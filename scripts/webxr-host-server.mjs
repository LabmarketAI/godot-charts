#!/usr/bin/env node
import { createServer } from "node:https";
import { appendFileSync, createReadStream, existsSync, mkdirSync, readFileSync, statSync } from "node:fs";
import { dirname, extname, join, normalize, resolve, sep } from "node:path";
import process from "node:process";

const args = parseArgs(process.argv.slice(2));
const root = resolve(args.root ?? process.env.WEBXR_ROOT ?? "/tmp/godot-webxr/web");
const host = args.host ?? process.env.WEBXR_HOST ?? "0.0.0.0";
const port = Number(args.port ?? process.env.WEBXR_PORT ?? 8457);
const cert = resolve(args.cert ?? process.env.WEBXR_CERT ?? ".local/webxr-host/certs/localhost.crt");
const key = resolve(args.key ?? process.env.WEBXR_KEY ?? ".local/webxr-host/certs/localhost.key");
const logPath = resolve(args.log ?? process.env.WEBXR_LOG ?? `.local/webxr-host/logs/webxr-${new Date().toISOString().replaceAll(":", "-")}.log`);

if (!existsSync(root) || !statSync(root).isDirectory()) {
  die(`Web export directory does not exist: ${root}`);
}
if (!existsSync(join(root, "index.html"))) {
  die(`Web export directory is missing index.html: ${root}`);
}
if (!existsSync(cert) || !existsSync(key)) {
  die(`Missing TLS files. Expected:\n  ${cert}\n  ${key}`);
}

const mimeTypes = new Map([
  [".html", "text/html; charset=utf-8"],
  [".js", "text/javascript; charset=utf-8"],
  [".wasm", "application/wasm"],
  [".pck", "application/octet-stream"],
  [".json", "application/json; charset=utf-8"],
  [".svg", "image/svg+xml"],
  [".png", "image/png"],
  [".jpg", "image/jpeg"],
  [".jpeg", "image/jpeg"],
  [".ico", "image/x-icon"],
]);

const server = createServer({ cert: readFileSync(cert), key: readFileSync(key) }, (request, response) => {
  const url = new URL(request.url ?? "/", `https://${request.headers.host ?? "localhost"}`);
  if (url.pathname === "/__webxr_log") {
    handleClientLog(request, response);
    return;
  }

  const pathname = decodeURIComponent(url.pathname);
  const file = safePath(root, pathname === "/" ? "/index.html" : pathname);
  if (!file || !existsSync(file) || !statSync(file).isFile()) {
    response.writeHead(404, { "content-type": "text/plain; charset=utf-8" });
    response.end("Not found\n");
    return;
  }

  response.writeHead(200, {
    "content-type": mimeTypes.get(extname(file)) ?? "application/octet-stream",
    "cache-control": "no-store",
    "cross-origin-opener-policy": "same-origin",
    "cross-origin-embedder-policy": "require-corp",
  });

  if (extname(file) === ".html") {
    response.end(injectLogging(readFileSync(file, "utf8")));
    return;
  }
  createReadStream(file).pipe(response);
});

server.listen(port, host, () => {
  console.log(`Serving Godot WebXR export from: ${root}`);
  console.log(`HTTPS host: https://${host === "0.0.0.0" ? "<this-machine-ip>" : host}:${port}/`);
  console.log(`Quest/browser log: ${logPath}`);
});

server.on("error", (error) => {
  console.error(`Failed to start HTTPS server on ${host}:${port}: ${error.message}`);
  process.exit(1);
});

function parseArgs(values) {
  const parsed = {};
  for (let index = 0; index < values.length; index += 1) {
    const value = values[index];
    if (!value.startsWith("--")) continue;
    parsed[value.slice(2)] = values[index + 1];
    index += 1;
  }
  return parsed;
}

function safePath(base, pathname) {
  const candidate = normalize(join(base, pathname));
  return candidate === base || candidate.startsWith(`${base}${sep}`) ? candidate : null;
}

function handleClientLog(request, response) {
  if (request.method !== "POST") {
    response.writeHead(405, { "content-type": "text/plain; charset=utf-8" });
    response.end("Method not allowed\n");
    return;
  }

  let body = "";
  request.setEncoding("utf8");
  request.on("data", (chunk) => {
    body += chunk;
    if (body.length > 256 * 1024) request.destroy();
  });
  request.on("end", () => {
    const line = formatClientLog(request, body);
    mkdirSync(dirname(logPath), { recursive: true });
    appendFileSync(logPath, `${line}\n`);
    console.log(line);
    response.writeHead(204);
    response.end();
  });
}

function formatClientLog(request, body) {
  let payload;
  try {
    payload = JSON.parse(body);
  } catch {
    payload = { level: "raw", message: body };
  }
  return JSON.stringify({
    time: new Date().toISOString(),
    remote: request.socket.remoteAddress ?? "unknown",
    ...payload,
  });
}

function injectLogging(html) {
  const script = `
<script>
(() => {
  const send = (payload) => {
    try {
      fetch("/__webxr_log", {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({ source: "browser", url: location.href, userAgent: navigator.userAgent, ...payload }),
        keepalive: true
      }).catch(() => {});
    } catch (_) {}
  };
  const stringify = (value) => {
    try {
      if (value instanceof Error) return value.stack || value.message;
      return typeof value === "string" ? value : JSON.stringify(value);
    } catch (_) {
      return String(value);
    }
  };
  for (const level of ["log", "warn", "error"]) {
    const original = console[level].bind(console);
    console[level] = (...args) => {
      send({ level, message: args.map(stringify).join(" ") });
      original(...args);
    };
  }
  window.addEventListener("error", (event) => {
    send({ level: "error", message: event.message, file: event.filename, line: event.lineno, column: event.colno });
  });
  window.addEventListener("unhandledrejection", (event) => {
    send({ level: "error", message: stringify(event.reason) });
  });
  send({ level: "info", message: "WebXR host logging attached" });
})();
</script>`;
  return html.includes("</head>") ? html.replace("</head>", `${script}\n</head>`) : `${script}\n${html}`;
}

function die(message) {
  console.error(message);
  process.exit(1);
}
