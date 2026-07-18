# Testing the Godot Charts WebXR build on a headset

This runbook certifies a release candidate against the physical-headset row in the [M3 release matrix](../openspec/changes/rebuild-data-scientist-xr-charting/m3-release-matrix.md). A successful export or desktop browser run is not headset certification.

## What you need

- A WebXR-capable VR headset and browser with tracked pose, controller ray, and select input.
- The exact release candidate built with standard Godot 4.6.3 and its matching web export templates.
- An HTTPS URL the headset can reach and trust. HTTP on another computer's LAN address is not a secure context; `localhost` exceptions apply to the device running the browser, not to your development computer.
- A way to record the headset, browser/runtime version, refresh rate, render scale, controller profile, performance telemetry, and observations. Browser remote debugging or vendor performance overlays are useful but not mandatory if their absence is recorded.
- A clear, stationary play area. Remain seated or standing in place; this test does not require walking.

Do not put credentials, private WSS tokens, or sensitive datasets in the URL or exported project.

## 1. Run the automated preflight

From the repository root:

```bash
GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64 \
GODOT_EXPORT_DATA_HOME=/path/to/godot-export-data \
BROWSER_BIN=brave-browser \
M3_REPORT_PATH=/tmp/godot-charts-flat-web-report.json \
scripts/test-web-browser.sh

GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64 \
scripts/test-webxr-session.sh
```

Both commands must pass. Keep the JSON report with the release evidence. The first command is a desktop mono-browser baseline, not a stereo result.

## 2. Build the candidate

```bash
GODOT_BIN=/path/to/Godot_v4.6.3-stable_linux.x86_64 \
GODOT_EXPORT_DATA_HOME=/path/to/godot-export-data \
scripts/build-web-example.sh /tmp/godot-charts-webxr-candidate
```

Deploy the contents of `/tmp/godot-charts-webxr-candidate/web/` unchanged to a versioned HTTPS path. The server must provide:

- `text/html` for HTML;
- `text/javascript` for JavaScript;
- `application/wasm` for WebAssembly;
- `application/octet-stream` for PCK files;
- a certificate trusted by the headset;
- no mixed HTTP resources;
- WSS, not WS, for an optional live endpoint.

Use the CSP, cache, CORS, and WSS Origin rules documented in the M3 release matrix. A self-signed certificate is suitable only if its issuing certificate has been deliberately installed and trusted on the headset. For most tests, a normal trusted certificate on a temporary versioned deployment is less error-prone.

## 3. Record the environment before entering VR

Create a copy of the physical WebXR row in the release matrix and record:

- date, candidate identifier, and deployment URL without credentials;
- headset model, OS/runtime version, and power mode;
- browser name and exact version;
- controller model/profile and whether hands are enabled;
- configured refresh rate and render scale/resolution;
- room-scale, stationary, or seated boundary mode;
- network type and whether a live WSS endpoint is enabled;
- telemetry source used for frame time, memory, and thermal observations.

Start from a cool device at a documented battery level. Disable unrelated recording, casting, and background applications unless they are intentionally part of the tested configuration.

## 4. Verify flat-web behavior in the headset browser

1. Open the HTTPS candidate URL in the headset browser.
2. Confirm the scene reports revision 1 and four rendered points, with no fatal loading message.
3. Confirm the linked table, status, help, and `Enter VR` control are readable.
4. Use a pointer/controller-as-pointer to activate at least one ordinary flat-web control.
5. Select **Frame** mode before entering VR when using the M1 flat-web reference scene. The tracked WebXR template chart starts with frame controls already visible.
6. Confirm the status says immersive VR is available. If it says unavailable, record the browser/runtime result and stop; do not count the tier as passed.

## 5. Verify immersive entry and baseline ray/select

1. Activate **Enter VR** with a deliberate user gesture.
2. Confirm the browser presents its normal permission/session UI and the application enters VR without reloading.
3. Record the selected reference space shown by diagnostics. The session requires the `local-floor` feature and requests `bounded-floor`, `local-floor`, then `local`; a selected `bounded-floor` or `local-floor` space satisfies the floor-relative baseline. Treat `local` as a degraded fallback and do not pass the current tier unless the matrix explicitly accepts and explains it.
4. Confirm the analytical frame appears at a comfortable authored pose and scale, the title and axes are readable, and the view is stereo rather than a flat browser quad.
5. Aim a tracked controller at the lower front cyan frame handle and press/hold select. Move the tracked controller a small distance. Release select to commit the previewed frame move.
6. Aim at the lower front orange frame handle and press/hold select. Move around the frame's vertical axis. Release select to commit the previewed frame rotation.
7. Confirm the frame moved or rotated once, capture ended on release, revision 1 remains active, and the four points/table content did not change.
8. Aim at one X/Y/Z endpoint thumb outside the plot bounds and press/hold select. Drag roughly along that axis, then release.
9. Confirm the endpoint interaction prints `chart-domain-preview` while held and `chart-domain-commit` on release, the chart/guides re-render, observer pose does not change, and the scale domain remains valid. Record if the endpoint handle is visible but cannot be acquired.
10. Repeat the frame move using squeeze only if the runtime exposes it. Squeeze is an enhancement; failure or absence of squeeze is not a baseline failure.
11. If hand tracking is exposed, record whether it works, but verify that no required step depends on hands.

Fail the baseline input tier if ray/select has no tracked aim pose, cannot select and commit a frame move, commits repeatedly, or changes analytical revision/content. Treat axis-domain endpoint failure as a chart-native-control failure, not as a failure of the previously established frame-move baseline, unless the release matrix declares endpoint handles required for that tier.

## 6. Verify cancellation, exit, and capability loss

Perform each applicable case and record the resulting revision, frame state, and browser mode:

1. Begin a frame move, then intentionally interrupt tracking before release. The uncommitted capture must cancel rather than partially commit.
2. Begin an axis-domain endpoint drag, then intentionally interrupt tracking before release if the runtime permits this safely. The uncommitted domain preview should cancel or terminate cleanly without leaving an invalid domain.
3. Use **Exit VR**, the browser's exit action, or the headset's normal session-exit control. The application must return to flat web without a page reload and retain committed frame state and revision.
4. Re-enter VR and confirm the same analytical state is presented.
5. During a second active capture, cause a safe session loss—such as ending the immersive session from browser/runtime controls. Do not remove the headset in a way that risks the tester. The capture must cancel and flat-web mode must recover.
6. In flat web, use **Reset** and confirm the authored frame pose returns while revision 1 and the four points remain valid.

If testing live data, also interrupt the network or WSS service. The recorded/offline plot must remain usable and the transport failure must be visible without exposing credentials.

## 7. Measure performance and thermal behavior

Warm the scene for at least one minute before recording. Then collect:

- stereo application/GPU frame time p50, p95, and maximum;
- refresh rate and missed/reprojected frame count;
- command-to-visible-update latency for at least 20 select/move/commit operations and, when endpoint handles are in scope, at least 10 axis-domain preview/commit operations;
- application/browser memory at warm-up and at the end;
- browser or runtime crashes, WebGL context loss, and session loss;
- device temperature or the available vendor thermal level;
- clock throttling, refresh-rate reduction, or worsening p95 frame time.

Run the fixed four-point scene continuously for 15 minutes. At minutes 0, 5, 10, and 15, perform five small select/move/commit operations and record the same telemetry. Keep the headset awake and the immersive session active. If the platform exposes no reliable memory or temperature value, write `unavailable`, name the telemetry source checked, and record frame degradation/throttling observations instead of inventing a number.

Candidate timing gates are:

- 72 Hz stereo: p95 no greater than 13.9 ms, with no sustained missed-frame sequence;
- optional 90 Hz tier: p95 no greater than 11.1 ms;
- semantic command update: p95 no greater than 75 ms over at least 20 operations.

Do not substitute the desktop `requestAnimationFrame` result for stereo headset timing or motion-to-photon latency.

## 8. Record the result

Update the physical row in `openspec/changes/rebuild-data-scientist-xr-charting/m3-release-matrix.md`. Attach or link, where the project stores release evidence:

- the flat-web JSON report;
- the exact exported candidate/build identifier;
- headset/browser/runtime screenshots or recordings;
- raw performance samples or overlay captures;
- the completed 15-minute observation log;
- every failed step and workaround.

Mark the row `Pass` only when entry, a floor-relative `bounded-floor` or `local-floor` reference space, readable stereo presentation, controller ray/select move/commit, revision preservation, exit/loss recovery, reset, budgets, and thermal/degradation checks all pass. Otherwise mark it `Fail` with the precise limitation. M3.7 remains open until at least one representative physical row passes.

## Troubleshooting

- **No Enter VR button:** confirm the page is HTTPS with a trusted certificate and that this exact browser/runtime supports `immersive-vr`. Check browser WebXR permissions and flags; do not bypass security controls in release evidence.
- **Button appears but entry fails:** capture the visible error, browser console, runtime version, and whether the failure occurred before or after permission UI.
- **Frame cannot be selected:** exit VR, choose **Frame** mode in flat web, re-enter, then verify the controller exposes tracked aim pose and select.
- **Scene is a flat quad:** the browser may still be showing its ordinary tab rather than an immersive WebXR session. Do not count this as stereo execution.
- **Works over desktop localhost but not on the headset:** the headset sees the development computer as a remote LAN host, so HTTP is not a secure context. Use trusted HTTPS reachable by the headset.
- **Wasm or PCK load failure:** verify response MIME types, CSP, cache freshness, and that all artifacts came from the same export.
- **Performance overlay changes timing:** record the tool and repeat once without capture/streaming enabled to quantify its overhead.
