---
name: headless-edge-cdp-fallback
description: "Drive a real browser via raw CDP over manually spawned headless Edge when omp's browser tools are broken (verified on this Windows box)."
---

# Headless Edge CDP fallback

Use when `xd://browser` fails (daemon unavailable / CDP attach timeout) and a real-browser check is required.

## 1. Spawn Edge
```js
const proc = Bun.spawn(["C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
  "--headless", "--remote-debugging-port=9336",
  `--user-data-dir=${require("os").tmpdir()}/omp-edge-${Date.now()}`, "about:blank"],
  { stdout: "ignore", stderr: "ignore" });
```
Launcher pid exits immediately — fine, CDP still answers (delegated instance).

## 2. Connect
```js
async function cdpUp(port) { for (let i=0;i<50;i++){ try { const r = await fetch(`http://127.0.0.1:${port}/json/version`); if (r.ok) return r.json(); } catch{} await new Promise(r=>setTimeout(r,200)); } throw new Error("CDP never came up"); }
const ver = await cdpUp(9336);
const targets = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
const ws = new WebSocket(targets[0].webSocketDebuggerUrl);
await new Promise(r => ws.onopen = r);
let seq = 0; const pending = new Map();
ws.onmessage = (e) => { const m = JSON.parse(e.data); if (m.id && pending.has(m.id)) { pending.get(m.id)(m); pending.delete(m.id); } };
const send = (method, params={}) => new Promise(res => { const id = ++seq; pending.set(id, res); ws.send(JSON.stringify({id, method, params})); });
const evalJs = (expr) => send("Runtime.evaluate", { expression: expr, returnByValue: true, awaitPromise: true })
  .then(m => m.result?.result?.value ?? m.result?.exceptionDetails);
```
First target on a fresh profile may be a Proton Pass extension tab — just navigate it.

## 3. Setup (all REQUIRED for reliable runs)
```js
await send("Page.enable");
await send("Emulation.setDeviceMetricsOverride", { width: 375, height: 727, deviceScaleFactor: 1, mobile: true });
await send("Emulation.setEmulatedMedia", { features: [{ name: "hover", value: "none" }] }); // touch env; skip for desktop checks
await send("Page.navigate", { url: "http://localhost:4323/" });
await send("Page.bringToFront");
await send("Emulation.setFocusEmulationEnabled", { enabled: true });
```
Then assert unthrottled rendering BEFORE sampling animations:
```js
const s = await evalJs(`({ vis: document.visibilityState, raf: await new Promise(r => { let n=0, t0=performance.now(); const f=()=>{ if(++n===10) r(performance.now()-t0); else requestAnimationFrame(f); }; requestAnimationFrame(f); }) })`);
// vis==='visible' && raf < ~300ms; otherwise re-bringToFront
```
Throttled tabs (~1000ms rAF) freeze CSS transitions — looks like a frozen app.

## 4. Interact
- Hydration: poll for the interactive element up to ~10s; `.click()` via Runtime.evaluate (React synthetic events fire). If first click opens nothing, re-click after 1s.
- Computed styles / geometry: `getComputedStyle`, `getBoundingClientRect` via evalJs.
- Hit-testing visibility: `document.elementFromPoint(x, y)` and compare against expected selectors.

## 5. Screenshots
```js
const shot = await send("Page.captureScreenshot", { format: "png" }); // base64 at shot.result.data
await Bun.write(Bun.env.TEMP + "/shot.png", Buffer.from(shot.result.data, "base64"));
```
Display with the `read` tool on the PNG path.

## 6. Cleanup
- `ws.close()`
- Kill ONLY spawned instances (real Edge survives): via eval JS — bash mangles PowerShell quoting:
```js
const p = Bun.spawn(["powershell","-NoProfile","-Command",
  `Get-CimInstance Win32_Process -Filter "Name='msedge.exe'" | Where-Object { $_.CommandLine -match 'headless' -and $_.CommandLine -match 'remote-debugging-port' } | ForEach-Object { taskkill /PID $_.ProcessId /T /F | Out-Null; $_.ProcessId }`]);
const killed = await new Response(p.stdout).text();
```
Do NOT wrap Bun.spawn in a custom Promise around `.exited` — a wrong construct hangs the kernel until timeout. `await new Response(proc.stdout).text()` directly.
