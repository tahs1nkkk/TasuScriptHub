import { getConfig, loadEnvironment } from "../src/config.mjs";

await loadEnvironment();
const config = getConfig();

if (!config.discordBotToken || !config.discordChannelId) {
  console.error("Discord bot tokeni veya kanal kimligi eksik.");
  process.exitCode = 1;
} else {
  const headers = { Authorization: `Bot ${config.discordBotToken}` };
  const [meResponse, guildsResponse, channelResponse] = await Promise.all([
    fetch("https://discord.com/api/v10/users/@me", { headers }),
    fetch("https://discord.com/api/v10/users/@me/guilds", { headers }),
    fetch(`https://discord.com/api/v10/channels/${config.discordChannelId}`, { headers })
  ]);

  const me = await safeJson(meResponse);
  const guilds = await safeJson(guildsResponse);
  const channel = await safeJson(channelResponse);
  console.log(JSON.stringify({
    botAuthentication: meResponse.status,
    botUsername: meResponse.ok ? me.username : null,
    guildMemberships: guildsResponse.ok && Array.isArray(guilds) ? guilds.length : null,
    guildLookupStatus: guildsResponse.status,
    channelAccess: channelResponse.status,
    channelName: channelResponse.ok ? channel.name : null,
    channelError: channelResponse.ok ? null : channel.message,
    channelErrorCode: channelResponse.ok ? null : channel.code,
    inviteUrl: meResponse.ok
      ? `https://discord.com/oauth2/authorize?client_id=${me.id}&permissions=101376&scope=bot`
      : null
  }, null, 2));
  if (!meResponse.ok || !channelResponse.ok) process.exitCode = 1;
}

async function safeJson(response) {
  try {
    return await response.json();
  } catch {
    return {};
  }
}
