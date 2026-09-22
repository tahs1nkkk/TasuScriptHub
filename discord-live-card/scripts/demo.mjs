import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { getAvatarMap } from "../src/avatars.mjs";
import { renderCard } from "../src/card.mjs";
import { ROOT } from "../src/config.mjs";
import { validateSnapshot } from "../src/state.mjs";

const base = {
  eventId: "demo-1",
  sessionId: "demo-session",
  phase: "round",
  map: "Research Facility",
  round: 7,
  murderer: { userId: 1, username: "Roblox", displayName: "Roblox" },
  detective: { userId: 156, username: "builderman", displayName: "Builderman" },
  winner: "none"
};

const deadSnapshot = validateSnapshot({
  ...base,
  eventId: "demo-dead",
  detectiveAlive: false,
  gun: { status: "dropped", holder: null }
});
const pickedUpSnapshot = validateSnapshot({
  ...base,
  eventId: "demo-picked-up",
  detectiveAlive: false,
  gun: { status: "picked_up", holder: { userId: 261, username: "Shedletsky", displayName: "Shedletsky" } }
});

const dataDir = path.join(ROOT, "data");
await mkdir(dataDir, { recursive: true });
const avatarMap = await getAvatarMap([base.murderer, base.detective, pickedUpSnapshot.gun.holder]);
const deadImage = await renderCard(deadSnapshot, avatarMap);
const pickedUpImage = await renderCard(pickedUpSnapshot, avatarMap);
const outputs = [
  ["preview-detective-dead.png", deadImage],
  ["preview-gun-picked-up.png", pickedUpImage],
  ["preview.png", pickedUpImage]
];
for (const [filename, image] of outputs) {
  const output = path.join(dataDir, filename);
  await writeFile(output, image);
  console.log(output);
}

for (const [systemStatus, filename] of [
  ["waiting", "preview-game-not-detected.png"],
  ["disconnected", "preview-mm2-disconnected.png"],
  ["offline", "preview-service-offline.png"]
]) {
  const systemSnapshot = {
    ...deadSnapshot,
    eventId: `demo-${systemStatus}`,
    murderer: null,
    detective: null,
    detectiveAlive: true,
    gun: { status: "unknown", holder: null },
    systemStatus,
    receivedAt: new Date().toISOString()
  };
  const image = await renderCard(systemSnapshot);
  const output = path.join(dataDir, filename);
  await writeFile(output, image);
  console.log(output);
}
