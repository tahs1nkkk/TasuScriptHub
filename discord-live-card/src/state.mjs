const PHASES = new Set(["lobby", "round", "ended"]);
const GUN_STATUSES = new Set(["unknown", "held", "dropped", "picked_up"]);
const WINNERS = new Set(["murderer", "innocents", "none"]);

export function validateSnapshot(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    throw validationError("JSON govdesi bir nesne olmali.");
  }

  const phase = cleanString(input.phase, 16).toLowerCase();
  if (!PHASES.has(phase)) throw validationError("phase lobby, round veya ended olmali.");

  const gunInput = input.gun && typeof input.gun === "object" ? input.gun : {};
  const gunStatus = cleanString(gunInput.status || "unknown", 20).toLowerCase();
  if (!GUN_STATUSES.has(gunStatus)) {
    throw validationError("gun.status unknown, held, dropped veya picked_up olmali.");
  }

  const winner = cleanString(input.winner || "none", 16).toLowerCase();
  if (!WINNERS.has(winner)) throw validationError("winner murderer, innocents veya none olmali.");

  return {
    eventId: cleanString(input.eventId, 100) || crypto.randomUUID(),
    sessionId: cleanString(input.sessionId, 100) || "default",
    phase,
    map: cleanString(input.map, 60),
    round: optionalInteger(input.round, 0, 1_000_000),
    murderer: normalizePlayer(input.murderer),
    detective: normalizePlayer(input.detective),
    detectiveAlive: normalizeDetectiveAlive(input.detectiveAlive, gunStatus),
    gun: {
      status: gunStatus,
      holder: normalizePlayer(gunInput.holder)
    },
    winner,
    sentAt: cleanString(input.sentAt, 40),
    receivedAt: new Date().toISOString()
  };
}

function normalizeDetectiveAlive(value, gunStatus) {
  if (typeof value === "boolean") return value;
  return gunStatus !== "dropped" && gunStatus !== "picked_up";
}

export function publicState(snapshot, publish = {}) {
  return {
    ...snapshot,
    publish: {
      mode: publish.mode || "preview",
      messageId: publish.messageId || null,
      updatedAt: publish.updatedAt || null,
      error: publish.error || null
    }
  };
}

export function phaseLabel(phase) {
  return ({ lobby: "ANA MENÜ", round: "TUR DEVAM EDİYOR", ended: "TUR BİTTİ" })[phase] || "BİLİNMİYOR";
}

export function gunLabel(gun) {
  return ({
    unknown: "Silah durumu bilinmiyor",
    held: "Silah dedektifte",
    dropped: "Silah yerde",
    picked_up: gun?.holder ? `Silahı ${gun.holder.displayName || gun.holder.username} aldı` : "Silah alındı"
  })[gun?.status] || "Silah durumu bilinmiyor";
}

function normalizePlayer(value) {
  if (value == null) return null;
  if (typeof value !== "object" || Array.isArray(value)) throw validationError("Oyuncu alani nesne veya null olmali.");
  const userId = optionalInteger(value.userId, 1, Number.MAX_SAFE_INTEGER);
  if (!userId) throw validationError("Oyuncu userId alani pozitif bir tam sayi olmali.");
  return {
    userId,
    username: cleanString(value.username, 40) || `User ${userId}`,
    displayName: cleanString(value.displayName, 50) || cleanString(value.username, 40) || `User ${userId}`
  };
}

function cleanString(value, maxLength) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function optionalInteger(value, min, max) {
  if (value == null || value === "") return null;
  const number = Number(value);
  return Number.isSafeInteger(number) && number >= min && number <= max ? number : null;
}

function validationError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}
