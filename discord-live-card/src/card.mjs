import sharp from "sharp";
import { phaseLabel } from "./state.mjs";

const WIDTH = 1200;
const HEIGHT = 630;

export async function renderCard(snapshot, avatarMap = new Map()) {
  const status = cardStatus(snapshot);
  const roles = buildRoles(snapshot);
  const columns = 2;
  const gap = 22;
  const side = 42;
  const cardWidth = Math.floor((WIDTH - side * 2 - gap * (columns - 1)) / columns);
  const svg = `
  <svg width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#070A13"/><stop offset=".5" stop-color="#10152A"/><stop offset="1" stop-color="#090B18"/></linearGradient>
      <filter id="shadow"><feDropShadow dx="0" dy="18" stdDeviation="22" flood-color="#000" flood-opacity=".45"/></filter>
    </defs>
    <rect width="1200" height="630" rx="38" fill="url(#bg)"/>
    <text x="44" y="60" fill="#F7F8FF" font-family="Arial, sans-serif" font-size="26" font-weight="700">MM2 LIVE</text>
    <text x="44" y="94" fill="#9BA6C7" font-family="Arial, sans-serif" font-size="18">${escapeXml(status.message || metaLine(snapshot))}</text>
    <text x="1156" y="67" text-anchor="end" fill="${status.color}" font-family="Arial, sans-serif" font-size="17" font-weight="700">${escapeXml(status.label)}</text>
    ${roles.map((role, index) => roleMarkup(role, side + index * (cardWidth + gap), 128, cardWidth, 448, avatarMap.get(role.player?.userId), status.color)).join("\n")}
    <text x="1156" y="590" text-anchor="end" fill="#6F799B" font-family="Arial, sans-serif" font-size="15">${escapeXml(formatTime(snapshot.receivedAt))}</text>
  </svg>`;

  return sharp(Buffer.from(svg)).png({ compressionLevel: 9 }).toBuffer();
}

function buildRoles(snapshot) {
  if (snapshot.systemStatus) {
    const content = {
      waiting: ["OYUN", "Oyun algılanmadı", "BAĞLANTI", "MM2 scripti bekleniyor", "#57E389"],
      disconnected: ["MM2", "Bağlantı kesildi", "SCRIPT", "Heartbeat alınamadı", "#FF9F43"],
      offline: ["YEREL SERVİS", "Servis kapalı", "GÜNCELLEME", "Kart güncellemeleri durdu", "#FF315F"]
    }[snapshot.systemStatus] || ["DURUM", "Bilinmiyor", "BAĞLANTI", "Bekleniyor", "#7782A5"];
    return [
      { label: content[0], player: null, accent: content[4], fallback: content[1], dead: false },
      { label: content[2], player: null, accent: content[4], fallback: content[3], dead: false }
    ];
  }
  const heroHasGun = snapshot.gun?.status === "picked_up" && snapshot.gun.holder;
  return [
    { label: "KATİL", player: snapshot.murderer, accent: "#FF315F", fallback: "Henüz algılanmadı", dead: false },
    heroHasGun
      ? { label: "SİLAHI ALAN", player: snapshot.gun.holder, accent: "#26A7FF", fallback: "—", dead: false }
      : { label: "DEDEKTİF", player: snapshot.detective, accent: "#26A7FF", fallback: "Henüz algılanmadı", dead: snapshot.detectiveAlive === false }
  ];
}

function roleMarkup(role, x, y, width, height, avatar, statusColor) {
  const imageSize = Math.min(260, width - 48);
  const imageX = x + (width - imageSize) / 2;
  const imageY = y + 76;
  const deadOverlay = role.dead
    ? `<rect x="${imageX}" y="${imageY}" width="${imageSize}" height="${imageSize}" rx="26" fill="#05060B" fill-opacity=".1"/>
       <line x1="${imageX + 44}" y1="${imageY + 44}" x2="${imageX + imageSize - 44}" y2="${imageY + imageSize - 44}" stroke="#FF274F" stroke-width="24" stroke-linecap="round"/>
       <line x1="${imageX + imageSize - 44}" y1="${imageY + 44}" x2="${imageX + 44}" y2="${imageY + imageSize - 44}" stroke="#FF274F" stroke-width="24" stroke-linecap="round"/>`
    : "";
  const image = avatar
    ? `<clipPath id="avatarClip${x}"><rect x="${imageX}" y="${imageY}" width="${imageSize}" height="${imageSize}" rx="26"/></clipPath><image href="data:image/png;base64,${avatar.toString("base64")}" x="${imageX}" y="${imageY}" width="${imageSize}" height="${imageSize}" preserveAspectRatio="xMidYMid meet" clip-path="url(#avatarClip${x})"/>${deadOverlay}`
    : `<rect x="${imageX}" y="${imageY}" width="${imageSize}" height="${imageSize}" rx="26" fill="#FFFFFF" fill-opacity=".045"/><text x="${x + width / 2}" y="${imageY + imageSize / 2 + 12}" text-anchor="middle" fill="#74809F" font-family="Arial, sans-serif" font-size="52">?</text>`;
  const displayName = role.player?.displayName || role.fallback;
  const username = role.player ? `@${role.player.username}` : "";
  return `
    <defs>
      <clipPath id="cardClip${x}"><rect x="${x}" y="${y}" width="${width}" height="${height}" rx="30"/></clipPath>
      <radialGradient id="roleGlow${x}"><stop stop-color="${role.accent}" stop-opacity=".36"/><stop offset="1" stop-color="${role.accent}" stop-opacity="0"/></radialGradient>
      <radialGradient id="statusGlow${x}"><stop stop-color="${statusColor}" stop-opacity=".33"/><stop offset="1" stop-color="${statusColor}" stop-opacity="0"/></radialGradient>
    </defs>
    <g filter="url(#shadow)">
      <rect x="${x}" y="${y}" width="${width}" height="${height}" rx="30" fill="#11172A" fill-opacity=".94" stroke="#FFFFFF" stroke-opacity=".11"/>
      <g clip-path="url(#cardClip${x})">
        <ellipse cx="${x + 22}" cy="${y + 40}" rx="${width * .62}" ry="205" fill="url(#roleGlow${x})"/>
        <ellipse cx="${x + width - 15}" cy="${y + height - 4}" rx="${width * .64}" ry="190" fill="url(#statusGlow${x})"/>
      </g>
    </g>
    <text x="${x + 24}" y="${y + 48}" fill="${role.accent}" font-family="Arial, sans-serif" font-size="18" font-weight="700" letter-spacing="2">${role.label}</text>
    ${image}
    <text x="${x + width / 2}" y="${y + 390}" text-anchor="middle" fill="#FFFFFF" font-family="Arial, sans-serif" font-size="24" font-weight="700">${escapeXml(truncate(displayName, 30))}</text>
    <text x="${x + width / 2}" y="${y + 420}" text-anchor="middle" fill="#AEB8D4" font-family="Arial, sans-serif" font-size="16">${escapeXml(truncate(username, 28))}</text>`;
}

function phaseColor(phase) {
  return ({ round: "#57E389", ended: "#FFC857", lobby: "#7782A5" })[phase] || "#7782A5";
}

function cardStatus(snapshot) {
  const system = {
    waiting: { label: "BOT AKTİF", message: "Oyun algılanmadı • MM2 bağlantısı bekleniyor", color: "#57E389" },
    disconnected: { label: "MM2 BAĞLANTISI YOK", message: "Yerel script bağlantısı kesildi", color: "#FF9F43" },
    offline: { label: "SERVİS KAPALI", message: "Yerel uygulama güvenli şekilde kapatıldı", color: "#FF315F" }
  }[snapshot.systemStatus];
  return system || { label: phaseLabel(snapshot.phase), message: "", color: phaseColor(snapshot.phase) };
}

function metaLine(snapshot) {
  const parts = [];
  if (snapshot.map) parts.push(snapshot.map);
  if (snapshot.round != null) parts.push(`Tur ${snapshot.round}`);
  if (snapshot.phase === "ended" && snapshot.winner !== "none") {
    parts.push(snapshot.winner === "murderer" ? "Katiller kazandı" : "Masumlar kazandı");
  }
  return parts.join("  •  ") || "Canlı oyun durumu";
}

function formatTime(value) {
  try {
    return new Intl.DateTimeFormat("tr-TR", { hour: "2-digit", minute: "2-digit", second: "2-digit", timeZone: "Europe/Istanbul" }).format(new Date(value));
  } catch {
    return "";
  }
}

function truncate(value, max) {
  const chars = [...String(value || "")];
  return chars.length > max ? `${chars.slice(0, max - 1).join("")}…` : chars.join("");
}

function escapeXml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (char) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&apos;" })[char]);
}
