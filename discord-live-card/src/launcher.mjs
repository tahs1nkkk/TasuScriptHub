import http from "node:http";
import { spawn } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
const SERVER_FILE = path.join(ROOT, "src", "server.mjs");
const HOST = "127.0.0.1";
const PORT = 8786;
let starting = false;

const launcher = http.createServer(async (request, response) => {
  response.setHeader("Cache-Control", "no-store");
  response.setHeader("X-Content-Type-Options", "nosniff");
  const url = new URL(request.url || "/", `http://${request.headers.host || HOST}`);

  if (request.method === "GET" && url.pathname === "/health") {
    return json(response, 200, { ok: true, localOnly: true, starting });
  }
  if (request.method === "POST" && url.pathname === "/start") {
    if (await botIsRunning()) return json(response, 200, { ok: true, alreadyRunning: true });
    if (!starting) {
      starting = true;
      const child = spawn(process.execPath, [SERVER_FILE], {
        cwd: ROOT,
        detached: true,
        windowsHide: true,
        stdio: "ignore"
      });
      setTimeout(() => { starting = false; }, 5_000).unref();
      child.once("error", () => { starting = false; });
      child.unref();
    }
    return json(response, 202, { ok: true, starting: true });
  }
  return json(response, 404, { error: "Bulunamadi." });
});

launcher.listen(PORT, HOST, () => {
  console.log(`TasuHub yerel baslatici: http://${HOST}:${PORT}`);
});

async function botIsRunning() {
  try {
    const response = await fetch("http://127.0.0.1:8787/health", { signal: AbortSignal.timeout(500) });
    return response.ok;
  } catch {
    return false;
  }
}

function json(response, status, body) {
  const encoded = Buffer.from(JSON.stringify(body));
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Content-Length": encoded.length });
  response.end(encoded);
}
