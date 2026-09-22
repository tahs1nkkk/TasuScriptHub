import test from "node:test";
import assert from "node:assert/strict";
import { gunLabel, phaseLabel, validateSnapshot } from "../src/state.mjs";

test("normalizes a valid live snapshot", () => {
  const result = validateSnapshot({
    phase: "ROUND",
    round: 4,
    murderer: { userId: 10, username: "murderer" },
    detective: { userId: 20, username: "detective", displayName: "Detective" },
    detectiveAlive: false,
    gun: { status: "picked_up", holder: { userId: 30, username: "hero" } },
    winner: "none"
  });
  assert.equal(result.phase, "round");
  assert.equal(result.murderer.displayName, "murderer");
  assert.equal(result.gun.holder.userId, 30);
  assert.equal(result.detectiveAlive, false);
  assert.match(gunLabel(result.gun), /hero/);
  assert.equal(phaseLabel(result.phase), "TUR DEVAM EDİYOR");
});

test("rejects unsupported phases", () => {
  assert.throws(() => validateSnapshot({ phase: "loading" }), /phase/);
});

test("accepts lobby without players", () => {
  const result = validateSnapshot({ phase: "lobby", gun: { status: "unknown" } });
  assert.equal(result.murderer, null);
  assert.equal(result.detective, null);
});
