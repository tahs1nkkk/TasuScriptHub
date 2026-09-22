const DISCORD_API = "https://discord.com/api/v10";

export async function upsertDiscordCard({ botToken, channelId, messageId, image, snapshot, fetchImpl = fetch }) {
  if (!botToken || !channelId) return { mode: "preview", messageId: null };
  validateBotConfig(botToken, channelId);
  const payload = {
    content: contentFor(snapshot),
    allowed_mentions: { parse: [] },
    attachments: [{ id: 0, filename: "roblox-live.png", description: "Guncel Roblox oyun durumu" }]
  };

  if (messageId) {
    const updateResponse = await sendMultipart(`${DISCORD_API}/channels/${channelId}/messages/${encodeURIComponent(messageId)}`, "PATCH", payload, image, botToken, fetchImpl);
    if (updateResponse.ok) {
      const body = await updateResponse.json();
      return { mode: "discord", messageId: body.id || messageId };
    }
    if (updateResponse.status !== 404) throw await discordError(updateResponse);
  }

  const createResponse = await sendMultipart(`${DISCORD_API}/channels/${channelId}/messages`, "POST", payload, image, botToken, fetchImpl);
  if (!createResponse.ok) throw await discordError(createResponse);
  const created = await createResponse.json();
  return { mode: "discord", messageId: created.id };
}

function sendMultipart(url, method, payload, image, botToken, fetchImpl) {
  const form = new FormData();
  form.append("payload_json", JSON.stringify(payload));
  form.append("files[0]", new Blob([image], { type: "image/png" }), "roblox-live.png");
  return fetchImpl(url, {
    method,
    headers: { Authorization: `Bot ${botToken}` },
    body: form,
    signal: AbortSignal.timeout(12_000)
  });
}

function validateBotConfig(botToken, channelId) {
  if (!/^\d{15,22}$/.test(channelId)) throw new Error("DISCORD_CHANNEL_ID gecerli bir kanal kimligi degil.");
  if (botToken.length < 40 || /\s/.test(botToken)) throw new Error("DISCORD_BOT_TOKEN gecerli gorunmuyor.");
}

function contentFor(snapshot) {
  if (snapshot.phase === "lobby") return "🕒 **Ana menü** — yeni tur bekleniyor.";
  if (snapshot.phase === "ended") {
    const winner = snapshot.winner === "murderer" ? "Katiller" : snapshot.winner === "innocents" ? "Masumlar" : "Sonuç bilinmiyor";
    return `🏁 **Tur bitti** — ${winner}`;
  }
  return "🟢 **Tur canlı** — kart otomatik güncelleniyor.";
}

async function discordError(response) {
  const body = (await response.text()).slice(0, 500);
  return new Error(`Discord bot API HTTP ${response.status}: ${body || response.statusText}`);
}
