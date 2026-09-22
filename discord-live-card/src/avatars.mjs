const CACHE_TTL_MS = 10 * 60 * 1000;
const cache = new Map();

export async function getAvatarMap(players, fetchImpl = fetch) {
  const uniqueIds = [...new Set(players.filter(Boolean).map((player) => player.userId))];
  const result = new Map();
  const missing = [];
  const now = Date.now();

  for (const userId of uniqueIds) {
    const cached = cache.get(userId);
    if (cached && cached.expiresAt > now) result.set(userId, cached.buffer);
    else missing.push(userId);
  }

  if (missing.length) {
    const params = new URLSearchParams({
      userIds: missing.join(","),
      size: "420x420",
      format: "Png",
      isCircular: "false"
    });
    try {
      const response = await fetchImpl(`https://thumbnails.roblox.com/v1/users/avatar?${params}`, {
        headers: { "User-Agent": "RobloxDiscordLiveCard/1.0" },
        signal: AbortSignal.timeout(8_000)
      });
      if (!response.ok) throw new Error(`Roblox thumbnail API HTTP ${response.status}`);
      const payload = await response.json();
      await Promise.all((payload.data || []).map(async (item) => {
        if (!item.imageUrl || item.state !== "Completed") return;
        const imageResponse = await fetchImpl(item.imageUrl, { signal: AbortSignal.timeout(8_000) });
        if (!imageResponse.ok) return;
        const buffer = Buffer.from(await imageResponse.arrayBuffer());
        cache.set(Number(item.targetId), { buffer, expiresAt: now + CACHE_TTL_MS });
        result.set(Number(item.targetId), buffer);
      }));
    } catch (error) {
      console.warn(`Avatarlar alinamadi: ${error.message}`);
    }
  }

  return result;
}

export function clearAvatarCache() {
  cache.clear();
}
