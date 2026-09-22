import http from "node:http";
import crypto from "node:crypto";
import { mkdir, readFile, rename, writeFile } from "node:fs/promises";
import path from "node:path";
import { getAvatarMap } from "./avatars.mjs";
import { renderCard } from "./card.mjs";
import { getConfig, loadEnvironment, ROOT } from "./config.mjs";
import { upsertDiscordCard } from "./discord.mjs";
import { publicState, validateSnapshot } from "./state.mjs";

await loadEnvironment();
const config = getConfig();
const dataDir = path.join(ROOT, "data");
const stateFile = path.join(dataDir, "live-state.json");
const previewFile = path.join(dataDir, "preview.png");
const mm2TelemetryFile = path.join(ROOT, "roblox", "TasuHubMM2Telemetry.luau");
await mkdir(dataDir, { recursive: true });

let stored = await loadStoredState();
let publishTimer = null;
let connectionTimer = null;
let shutdownTimer = null;
let publishChain = Promise.resolve();
let shuttingDown = false;
const seenEventIds = new Map();

const server = http.createServer(async (request, response) => {
  try {
    setHeaders(response);
    const url = new URL(request.url || "/", `http://${request.headers.host || "localhost"}`);
    if (request.method === "OPTIONS") return end(response, 204);

    if (request.method === "GET" && url.pathname === "/health") {
      return json(response, 200, {
        ok: true,
        localOnly: true,
        discordConfigured: Boolean(config.discordBotToken && config.discordChannelId),
        ingestTokenConfigured: config.ingestToken.length >= 32,
        hasState: Boolean(stored.snapshot),
        systemStatus: stored.snapshot?.systemStatus || "connected",
        connectionTimeoutMs: config.connectionTimeoutMs,
        autoShutdownMs: config.autoShutdownMs
      });
    }

    if (request.method === "GET" && url.pathname === "/api/state") {
      return json(response, 200, stored.snapshot ? publicState(stored.snapshot, stored.publish) : { snapshot: null });
    }

    if (request.method === "GET" && url.pathname === "/preview.png") {
      try {
        const image = await readFile(previewFile);
        response.writeHead(200, { "Content-Type": "image/png", "Cache-Control": "no-store", "Content-Length": image.length });
        return response.end(image);
      } catch (error) {
        if (error.code === "ENOENT") return json(response, 404, { error: "Henuz kart uretilmedi." });
        throw error;
      }
    }

    if (request.method === "GET" && url.pathname === "/client/mm2-telemetry.lua") {
      if (config.ingestToken.length < 32) return json(response, 503, { error: "INGEST_TOKEN yapilandirilmamis." });
      const source = await readFile(mm2TelemetryFile, "utf8");
      const injected = source.replaceAll("__INGEST_TOKEN__", escapeLuauString(config.ingestToken));
      return textResponse(response, 200, injected, "text/plain; charset=utf-8");
    }

    if (request.method === "POST" && url.pathname === "/v1/snapshot") {
      authenticate(request);
      const body = await readJson(request);
      const snapshot = validateSnapshot(body);
      purgeSeenEvents();
      if (seenEventIds.has(snapshot.eventId)) {
        return json(response, 200, { ok: true, duplicate: true, eventId: snapshot.eventId });
      }
      seenEventIds.set(snapshot.eventId, Date.now());
      stored.snapshot = snapshot;
      stored.publish = { ...stored.publish, error: null };
      await saveStoredState();
      scheduleConnectionWatch();
      schedulePublish();
      return json(response, 202, { ok: true, queued: true, eventId: snapshot.eventId });
    }

    if (request.method === "POST" && url.pathname === "/control/shutdown") {
      authenticate(request);
      json(response, 202, { ok: true, shuttingDown: true });
      setImmediate(() => void shutdown("MM2 module unloaded"));
      return;
    }

    return json(response, 404, { error: "Bulunamadi." });
  } catch (error) {
    const status = Number(error.statusCode) || 500;
    console.error(error);
    return json(response, status, { error: status >= 500 ? "Sunucu hatasi." : error.message });
  }
});

server.listen(config.port, config.host, () => {
  console.log(`Roblox Discord Live Card: http://${config.host}:${config.port}`);
  console.log("Ag erisimi: yalnizca bu bilgisayar (127.0.0.1)");
  console.log(`Discord modu: ${config.discordBotToken && config.discordChannelId ? "bot etkin" : "preview"}`);
  if (config.ingestToken.length < 32) console.warn("UYARI: INGEST_TOKEN en az 32 karakter olmadan POST istekleri reddedilir.");
  void setSystemState("waiting");
  scheduleAutoShutdown();
});

function schedulePublish() {
  clearTimeout(publishTimer);
  publishTimer = setTimeout(() => {
    publishChain = publishChain.then(publishLatest, publishLatest);
  }, config.debounceMs);
}

async function publishLatest() {
  const snapshot = stored.snapshot;
  if (!snapshot) return;
  try {
    const avatarMap = await getAvatarMap([snapshot.murderer, snapshot.detective, snapshot.gun?.holder]);
    const image = await renderCard(snapshot, avatarMap);
    await atomicWrite(previewFile, image);
    const discordResult = await upsertDiscordCard({
      botToken: config.discordBotToken,
      channelId: config.discordChannelId,
      messageId: stored.messageId,
      image,
      snapshot
    });
    stored.messageId = discordResult.messageId;
    stored.publish = { mode: discordResult.mode, messageId: discordResult.messageId, updatedAt: new Date().toISOString(), error: null };
    await saveStoredState();
    console.log(`[${snapshot.phase}] kart guncellendi (${discordResult.mode})`);
  } catch (error) {
    stored.publish = { ...stored.publish, updatedAt: new Date().toISOString(), error: error.message };
    await saveStoredState();
    console.error(`Yayin hatasi: ${error.message}`);
  }
}

async function setSystemState(systemStatus) {
  stored.snapshot = makeSystemSnapshot(systemStatus);
  stored.publish = { ...stored.publish, error: null };
  await saveStoredState();
  publishChain = publishChain.then(publishLatest, publishLatest);
  await publishChain;
}

function scheduleConnectionWatch() {
  clearTimeout(connectionTimer);
  connectionTimer = setTimeout(() => {
    if (!shuttingDown) void setSystemState("disconnected");
  }, config.connectionTimeoutMs);
  scheduleAutoShutdown();
}

function scheduleAutoShutdown() {
  clearTimeout(shutdownTimer);
  shutdownTimer = setTimeout(() => {
    if (!shuttingDown) void shutdown("MM2 heartbeat timeout");
  }, config.autoShutdownMs);
}

function makeSystemSnapshot(systemStatus) {
  return {
    eventId: `system:${systemStatus}:${Date.now()}`,
    sessionId: "local-service",
    phase: "lobby",
    map: "",
    round: null,
    murderer: null,
    detective: null,
    detectiveAlive: true,
    gun: { status: "unknown", holder: null },
    winner: "none",
    sentAt: new Date().toISOString(),
    receivedAt: new Date().toISOString(),
    systemStatus
  };
}

async function shutdown(signal) {
  if (shuttingDown) return;
  shuttingDown = true;
  clearTimeout(publishTimer);
  clearTimeout(connectionTimer);
  clearTimeout(shutdownTimer);
  console.log(`${signal}: servis kapali karti yayinlaniyor...`);
  try {
    await setSystemState("offline");
  } catch (error) {
    console.error(`Kapanis karti yayinlanamadi: ${error.message}`);
  }
  await new Promise((resolve) => server.close(resolve));
  process.exit(0);
}

process.once("SIGINT", () => void shutdown("SIGINT"));
process.once("SIGTERM", () => void shutdown("SIGTERM"));

function authenticate(request) {
  if (config.ingestToken.length < 32) throw httpError(503, "Sunucuda INGEST_TOKEN yapilandirilmamis.");
  const header = request.headers.authorization || "";
  const supplied = header.startsWith("Bearer ") ? header.slice(7) : "";
  const expectedBuffer = Buffer.from(config.ingestToken);
  const suppliedBuffer = Buffer.from(supplied);
  if (expectedBuffer.length !== suppliedBuffer.length || !crypto.timingSafeEqual(expectedBuffer, suppliedBuffer)) {
    throw httpError(401, "Gecersiz yetkilendirme.");
  }
}

async function readJson(request) {
  const chunks = [];
  let size = 0;
  for await (const chunk of request) {
    size += chunk.length;
    if (size > 64 * 1024) throw httpError(413, "JSON govdesi cok buyuk.");
    chunks.push(chunk);
  }
  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw httpError(400, "Gecersiz JSON.");
  }
}

async function loadStoredState() {
  try {
    const value = JSON.parse(await readFile(stateFile, "utf8"));
    return { snapshot: value.snapshot || null, messageId: value.messageId || null, publish: value.publish || {} };
  } catch {
    return { snapshot: null, messageId: null, publish: {} };
  }
}

async function saveStoredState() {
  await atomicWrite(stateFile, Buffer.from(JSON.stringify(stored, null, 2)));
}

async function atomicWrite(target, content) {
  const temporary = `${target}.${process.pid}.tmp`;
  await writeFile(temporary, content);
  await rename(temporary, target);
}

function purgeSeenEvents() {
  const cutoff = Date.now() - 10 * 60 * 1000;
  for (const [eventId, timestamp] of seenEventIds) if (timestamp < cutoff) seenEventIds.delete(eventId);
}

function setHeaders(response) {
  response.setHeader("X-Content-Type-Options", "nosniff");
  response.setHeader("Cache-Control", "no-store");
}

function json(response, status, body) {
  if (response.headersSent) return response.end();
  const encoded = Buffer.from(JSON.stringify(body));
  response.writeHead(status, { "Content-Type": "application/json; charset=utf-8", "Content-Length": encoded.length });
  response.end(encoded);
}

function textResponse(response, status, body, contentType) {
  if (response.headersSent) return response.end();
  const encoded = Buffer.from(body);
  response.writeHead(status, { "Content-Type": contentType, "Content-Length": encoded.length, "Cache-Control": "no-store" });
  response.end(encoded);
}

function escapeLuauString(value) {
  return String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\r/g, "\\r").replace(/\n/g, "\\n");
}

function end(response, status) {
  response.writeHead(status);
  response.end();
}

function httpError(statusCode, message) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}
