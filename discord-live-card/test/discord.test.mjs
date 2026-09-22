import test from "node:test";
import assert from "node:assert/strict";
import { upsertDiscordCard } from "../src/discord.mjs";

const botToken = "test.bot.token_that_is_long_enough_for_validation_123456789";
const channelId = "123456789012345678";
const snapshot = { phase: "round" };
const image = Buffer.from([137, 80, 78, 71]);

test("creates a Discord message when there is no saved message id", async () => {
  const calls = [];
  const fetchImpl = async (url, options) => {
    calls.push({ url, options });
    return Response.json({ id: "message-1" });
  };
  const result = await upsertDiscordCard({ botToken, channelId, messageId: null, image, snapshot, fetchImpl });
  assert.equal(result.messageId, "message-1");
  assert.equal(calls[0].options.method, "POST");
  assert.match(calls[0].url, /\/channels\/123456789012345678\/messages$/);
  assert.equal(calls[0].options.headers.Authorization, `Bot ${botToken}`);
  assert.ok(calls[0].options.body instanceof FormData);
});

test("updates the existing Discord message", async () => {
  const calls = [];
  const fetchImpl = async (url, options) => {
    calls.push({ url, options });
    return Response.json({ id: "message-1" });
  };
  const result = await upsertDiscordCard({ botToken, channelId, messageId: "message-1", image, snapshot, fetchImpl });
  assert.equal(result.messageId, "message-1");
  assert.equal(calls[0].options.method, "PATCH");
  assert.match(calls[0].url, /\/messages\/message-1$/);
});

test("rejects invalid Discord channel ids", async () => {
  await assert.rejects(
    upsertDiscordCard({ botToken, channelId: "not-a-channel", image, snapshot }),
    /kanal kimligi/
  );
});
