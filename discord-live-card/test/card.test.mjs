import test from "node:test";
import assert from "node:assert/strict";
import sharp from "sharp";
import { renderCard } from "../src/card.mjs";
import { validateSnapshot } from "../src/state.mjs";

test("renders a 1200x630 PNG without avatars", async () => {
  const snapshot = validateSnapshot({
    phase: "lobby",
    map: "Lobby",
    gun: { status: "unknown" },
    winner: "none"
  });
  const image = await renderCard(snapshot);
  assert.deepEqual([...image.subarray(0, 8)], [137, 80, 78, 71, 13, 10, 26, 10]);
  const metadata = await sharp(image).metadata();
  assert.equal(metadata.width, 1200);
  assert.equal(metadata.height, 630);
  assert.equal(metadata.format, "png");
});

test("renders local lifecycle status cards", async () => {
  for (const systemStatus of ["waiting", "disconnected", "offline"]) {
    const image = await renderCard({
      phase: "lobby",
      murderer: null,
      detective: null,
      detectiveAlive: true,
      gun: { status: "unknown", holder: null },
      winner: "none",
      receivedAt: new Date().toISOString(),
      systemStatus
    });
    const metadata = await sharp(image).metadata();
    assert.equal(metadata.width, 1200);
    assert.equal(metadata.height, 630);
  }
});
