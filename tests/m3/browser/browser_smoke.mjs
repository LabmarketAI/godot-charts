import { writeFile } from "node:fs/promises";

const [, , debugPort, reportPath] = process.argv;
if (!debugPort) throw new Error("Usage: node browser_smoke.mjs DEBUG_PORT");

const deadline = Date.now() + 30000;
let page;
while (Date.now() < deadline) {
  try {
    const targets = await fetch(`http://127.0.0.1:${debugPort}/json`).then((response) => response.json());
    page = targets.find((target) => target.type === "page" && target.url.startsWith("http://127.0.0.1:"));
    if (page) break;
  } catch {}
  await new Promise((resolve) => setTimeout(resolve, 100));
}
if (!page) throw new Error("Browser page did not expose a DevTools target.");

const socket = new WebSocket(page.webSocketDebuggerUrl);
await new Promise((resolve, reject) => {
  socket.addEventListener("open", resolve, { once: true });
  socket.addEventListener("error", reject, { once: true });
});

let nextId = 1;
const pending = new Map();
const browserErrors = [];
const browserConsole = [];
const inputLatenciesMs = [];
socket.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.id && pending.has(message.id)) {
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(JSON.stringify(message.error)));
    else resolve(message.result);
    return;
  }
  if (message.method === "Runtime.exceptionThrown") {
    browserErrors.push(message.params.exceptionDetails.text);
  }
  if (message.method === "Runtime.consoleAPICalled" && message.params.type === "error") {
    browserErrors.push(message.params.args.map((arg) => arg.value ?? arg.description).join(" "));
  }
  if (message.method === "Runtime.consoleAPICalled") {
    browserConsole.push(`${message.params.type}: ${message.params.args.map((arg) => arg.value ?? arg.description).join(" ")}`);
  }
});

function command(method, params = {}) {
  const id = nextId++;
  socket.send(JSON.stringify({ id, method, params }));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

async function evaluate(expression) {
  const result = await command("Runtime.evaluate", { expression, returnByValue: true, awaitPromise: true });
  if (result.exceptionDetails) {
    const details = result.exceptionDetails;
    const exception = details.exception?.description ?? details.exception?.value ?? details.text;
    const callFrames = details.stackTrace?.callFrames ?? [];
    const stack = callFrames.map((frame) => `${frame.functionName || "<anonymous>"}@${frame.url}:${frame.lineNumber + 1}:${frame.columnNumber + 1}`).join(" | ");
    throw new Error(`Browser evaluation failed: ${exception}${stack ? ` Stack: ${stack}` : ""}`);
  }
  return result.result.value;
}

async function waitForSmoke(expected = () => true) {
  const end = Date.now() + 30000;
  let lastValue = null;
  while (Date.now() < end) {
    const value = await evaluate("window.godotChartsSmoke || null");
    lastValue = value;
    if (value?.ready && expected(value)) return value;
    await new Promise((resolve) => setTimeout(resolve, 10));
  }
  throw new Error(`Timed out waiting for Godot browser diagnostics. Last state: ${JSON.stringify(lastValue)} Console: ${browserConsole.join(" | ")}`);
}

async function pressKey(key, code, virtualKeyCode) {
  const fields = { key, code, windowsVirtualKeyCode: virtualKeyCode, nativeVirtualKeyCode: virtualKeyCode };
  await command("Input.dispatchKeyEvent", { type: "keyDown", ...fields });
  await command("Input.dispatchKeyEvent", { type: "keyUp", ...fields });
}

async function pressKeyAndWait(key, code, virtualKeyCode, expected) {
  const started = performance.now();
  await pressKey(key, code, virtualKeyCode);
  const state = await waitForSmoke(expected);
  inputLatenciesMs.push(performance.now() - started);
  return state;
}

await command("Page.enable");
await command("Runtime.enable");
await command("Log.enable");
await command("Network.enable");
await command("Page.bringToFront");
await command("Emulation.setFocusEmulationEnabled", { enabled: true });
await evaluate(`new Promise((resolve, reject) => {
  const started = performance.now();
  function wait() {
    const canvas = document.querySelector("canvas");
    if (canvas) {
      canvas.focus();
      resolve(true);
      return;
    }
    if (performance.now() - started > 10000) {
      reject(new Error("Timed out waiting for Godot canvas"));
      return;
    }
    requestAnimationFrame(wait);
  }
  wait();
})`);

const initial = await waitForSmoke((value) => value.revision === 1 && value.rendered_points === 4 && value.webxr_state !== "checking");
if (initial.revision !== 1 || initial.rendered_points !== 4 || initial.mode !== "content") {
  throw new Error(`Unexpected startup state: ${JSON.stringify(initial)}`);
}
if (initial.webxr_state !== "unavailable" || !initial.webxr_message.includes("flat-web")) {
  throw new Error(`Headless browser did not expose WebXR fallback: ${JSON.stringify(initial)}`);
}
const transportFailed = await waitForSmoke((value) => value.live_transport?.diagnostics?.some((diagnostic) => diagnostic.code === "connection-failed"));
if (transportFailed.revision !== 1 || transportFailed.rendered_points !== 4 || transportFailed.live_transport.endpoint !== "wss://127.0.0.1:1") {
  throw new Error(`Failed WSS fallback changed recorded state or exposed an unsafe endpoint: ${JSON.stringify(transportFailed)}`);
}

await pressKeyAndWait("2", "Digit2", 50, (value) => value.mode === "frame");
await pressKeyAndWait("f", "KeyF", 70, (value) => value.selected);
await pressKeyAndWait("m", "KeyM", 77, (value) => value.capture === "move");
await pressKeyAndWait("ArrowRight", "ArrowRight", 39, (value) => value.capture === "move" && Math.abs(value.frame_position[0] - -1.25) <= 0.001);
const moved = await pressKeyAndWait("Enter", "Enter", 13, (value) => value.mode === "frame" && value.selected && value.capture === "none");
if (Math.abs(moved.frame_position[0] - -1.25) > 0.001) {
  throw new Error(`Browser keyboard workflow did not move the frame: ${JSON.stringify(moved)}`);
}

await command("Page.reload", { ignoreCache: false });
const reloaded = await waitForSmoke((value) => value.mode === "content" && value.revision === 1 && value.rendered_points === 4 && value.webxr_state !== "checking");
if (reloaded.revision !== 1 || reloaded.rendered_points !== 4 || Math.abs(reloaded.frame_position[0] - -1.5) > 0.001) {
  throw new Error(`Reload did not restore deterministic recorded state: ${JSON.stringify(reloaded)}`);
}
if (browserErrors.length) throw new Error(`Browser runtime errors: ${browserErrors.join(" | ")}`);

const frameTiming = await evaluate(`new Promise((resolve) => {
  const samples = [];
  let previous = performance.now();
  function sample(now) {
    samples.push(now - previous);
    previous = now;
    if (samples.length < 180) requestAnimationFrame(sample);
    else {
      samples.sort((a, b) => a - b);
      const percentile = (p) => samples[Math.min(samples.length - 1, Math.floor(samples.length * p))];
      resolve({ samples: samples.length, median_ms: percentile(0.5), p95_ms: percentile(0.95), max_ms: samples[samples.length - 1] });
    }
  }
  requestAnimationFrame(sample);
})`);
const heap = await command("Runtime.getHeapUsage");
const sortedInput = [...inputLatenciesMs].sort((a, b) => a - b);
const report = {
  state: reloaded,
  mono_frame_timing: frameTiming,
  input_latency: {
    samples: sortedInput.length,
    median_ms: sortedInput[Math.floor(sortedInput.length / 2)],
    max_ms: sortedInput[sortedInput.length - 1],
  },
  javascript_heap: { used_bytes: heap.usedSize, total_bytes: heap.totalSize },
};
if (reportPath) await writeFile(reportPath, `${JSON.stringify(report, null, 2)}\n`, "utf8");
console.log(`Godot Charts browser smoke passed: ${JSON.stringify(report)}`);
socket.close();
