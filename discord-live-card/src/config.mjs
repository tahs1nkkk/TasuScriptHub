import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const ROOT = path.dirname(path.dirname(fileURLToPath(import.meta.url)));

export async function loadEnvironment(file = path.join(ROOT, ".env")) {
  try {
    const source = await readFile(file, "utf8");
    for (const rawLine of source.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) continue;
      const separator = line.indexOf("=");
      if (separator < 1) continue;
      const key = line.slice(0, separator).trim();
      let value = line.slice(separator + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) || (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }
      if (!(key in process.env)) process.env[key] = value;
    }
  } catch (error) {
    if (error.code !== "ENOENT") throw error;
  }
}

export function getConfig() {
  const port = integer(process.env.PORT, 8787, 1, 65535);
  const debounceMs = integer(process.env.PUBLISH_DEBOUNCE_MS, 750, 100, 10_000);
  const connectionTimeoutMs = integer(process.env.CONNECTION_TIMEOUT_MS, 15_000, 5_000, 300_000);
  const autoShutdownMs = integer(process.env.AUTO_SHUTDOWN_MS, 30_000, connectionTimeoutMs + 1_000, 600_000);
  return {
    port,
    host: "127.0.0.1",
    ingestToken: process.env.INGEST_TOKEN || "",
    discordBotToken: process.env.DISCORD_BOT_TOKEN || "",
    discordChannelId: process.env.DISCORD_CHANNEL_ID || "",
    debounceMs,
    connectionTimeoutMs,
    autoShutdownMs
  };
}

function integer(value, fallback, min, max) {
  const parsed = Number.parseInt(value, 10);
  return Number.isInteger(parsed) && parsed >= min && parsed <= max ? parsed : fallback;
}
