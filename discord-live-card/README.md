# Roblox Discord Live Card

Yerel menuden gelen tur durumunu dogrular, Roblox avatar PNG'lerini resmi thumbnail API'sinden alir, iki oyunculu canli kart uretir ve mevcut Discord botuyla ayni kanal mesajini gunceller. Uygulama yalnizca `127.0.0.1` adresinde dinler; VPS veya harici uygulama sunucusu gerekmez.

> Discord bot tokeni yalnizca yerel `.env` dosyasinda tutulur ve Roblox/Luau koduna eklenmez.

## Desteklenen durumlar

- `lobby`: ana menu / tur bekleniyor
- `round`: katil, dedektif ve silah durumu canli
- `ended`: tur sonucu
- Silah: `held`, `dropped`, `picked_up`, `unknown`
- Kart daima iki oyuncu panelidir
- Dedektif oldugunde sag avatar kararir ve kirmizi X gorunur
- `picked_up` durumunda sag panel dedektif yerine silahi alan oyuncuyu gosterir ve X kalkar
- Ayni Discord mesaji `PATCH` ile guncellenir; her olayda yeni mesaj acilmaz
- PNG her guncellemede ayni `roblox-live.png` eki olarak mevcut mesajda degistirilir
- Discord ayari yokken `data/preview.png` yine uretilir
- Baslangic, baglanti kaybi ve kontrollu kapanis icin ayri durum kartlari vardir

## Kurulum

Node.js 20 veya yenisi gerekir.

```powershell
cd ".\discord-live-card"
npm install
Copy-Item .env.example .env
```

`.env` icinde:

1. En az 32 karakterlik rastgele `INGEST_TOKEN` belirleyin.
2. Discord bot tokenini `DISCORD_BOT_TOKEN` alanina koyun.
3. Hedef metin kanalinin kimligini `DISCORD_CHANNEL_ID` alanina koyun.
4. Bir kez `powershell -ExecutionPolicy Bypass -File .\install-launcher.ps1` calistirin. Bu, Windows oturumunda sessizce bekleyen yerel baslaticiyi kurar.

Gercek tokenleri `.env.example` dosyasinda tutmayin. `.env.example` yalnizca bos sablondur; gizli bilgiler `.gitignore` tarafindan dislanan `.env` dosyasinda kalmalidir.

## Discord bot baglantisi

Gerekli bilgiler:

- `DISCORD_BOT_TOKEN`: Discord Developer Portal > uygulamaniz > **Bot** > Reset Token / Copy Token
- `DISCORD_CHANNEL_ID`: Discord istemcisinde User Settings > Advanced > Developer Mode acikken hedef kanala sag tik > **Copy Channel ID**
- Botun sunucuda bulunmasi ve hedef kanali gorebilmesi
- Kanal izinleri: **View Channel**, **Send Messages**, **Attach Files** ve **Read Message History**

Bot henuz Discord sunucusuna eklenmediyse Developer Portal > OAuth2 > URL Generator bolumunde `bot` scope'unu ve yukaridaki dort izni secip uretilen davet adresini kullanin. Servis her tur icin yeni mesaj yagdirmaz; `data/live-state.json` icinde botun mesaj kimligini saklayip o mesaji duzenler. Mesaj Discord'da elle silinirse servis bir sonraki guncellemede otomatik olarak yenisini olusturur.

Bu servis slash command veya mesaj icerigi okumaz; dolayisiyla Message Content Intent gerekmez. Bot tokenini Roblox scriptine, GUI'ye veya istemci tarafina koymayin. Token yalnizca bu Node servisinin `.env` dosyasinda kalir.

## Kart durumlari

- Uygulama acilinca: **BOT AKTIF / Oyun algilanmadi**
- MM2 snapshot veya heartbeat gelince: normal canli tur karti
- `CONNECTION_TIMEOUT_MS` boyunca heartbeat gelmezse: **MM2 BAGLANTISI YOK**
- `AUTO_SHUTDOWN_MS` boyunca heartbeat gelmezse: **SERVIS KAPALI** karti yayinlanir ve asil bot sureci kapanir
- `Ctrl+C`, `SIGTERM` veya normal uygulama kapatma sirasinda: kapatmadan once **SERVIS KAPALI** karti

Ani elektrik kesintisi, bilgisayarin kilitlenmesi veya zorla `taskkill /F` durumunda uygulama kapanmadan Discord'a istek gonderemeyecegi icin kapali karti garanti edilemez. Normal kapatmada ayni Discord mesaji duzenlenir.

## Tamamen yerel akis

```text
Yerel menu/GUI -> http://127.0.0.1:8787/v1/snapshot
                 -> avatar PNG + kart uretimi
                 -> Discord Bot API (disariya giden HTTPS)
```

Windows oturumunda yalnizca hafif yerel baslatici bekler. Asil Discord bot sureci Catalog'da MM2 **RUN** tiklaninca acilir ve oyun/MM2 heartbeat'i kesilince otomatik kapanir. Modem portu acma, domain, VPS, tunnel veya public IP gerekmez. Discord'a mesaj gonderebilmesi ve Roblox avatarlarini alabilmesi icin bilgisayarin normal internet baglantisi gerekir.

Yerel fonksiyon testi:

```powershell
npm run demo
npm test
npm run check
```

Demo resmi `data/preview.png` olur.

## API testi

Sunucu calisirken PowerShell ile:

```powershell
$headers = @{ Authorization = "Bearer BURAYA_INGEST_TOKEN" }
$body = Get-Content -Raw .\examples\snapshot.json
Invoke-RestMethod -Method Post -Uri http://127.0.0.1:8787/v1/snapshot -Headers $headers -ContentType "application/json" -Body $body
```

- Saglik: `GET http://127.0.0.1:8787/health`
- Son durum: `GET http://127.0.0.1:8787/api/state`
- Son kart: `GET http://127.0.0.1:8787/preview.png`

## Yerel menu/GUI baglantisi

Yerel menu `POST http://127.0.0.1:8787/v1/snapshot` adresine `Authorization: Bearer INGEST_TOKEN` basligi ve `examples/snapshot.json` biciminde JSON yollar. Ornek Luau adapteri `roblox/` klasorundedir. Kendi tur yoneticiniz asagidaki degerleri gunceller:

| Attribute | Ornek |
|---|---|
| `RoundPhase` | `lobby`, `round`, `ended` |
| `MapName` | `Research Facility` |
| `RoundNumber` | `12` |
| `MurdererUserId` | Roblox user ID |
| `DetectiveUserId` | Roblox user ID |
| `DetectiveAlive` | `true` / `false` |
| `GunStatus` | `held`, `dropped`, `picked_up` |
| `GunHolderUserId` | Silahi alan user ID |
| `RoundWinner` | `murderer`, `innocents`, `none` |

Ornek tur yoneticisi guncellemesi:

```luau
workspace:SetAttribute("RoundPhase", "round")
workspace:SetAttribute("MurdererUserId", murderer.UserId)
workspace:SetAttribute("DetectiveUserId", detective.UserId)
workspace:SetAttribute("DetectiveAlive", true)
workspace:SetAttribute("GunStatus", "held")

-- Dedektif oldugunde:
workspace:SetAttribute("DetectiveAlive", false)
workspace:SetAttribute("GunStatus", "dropped")
workspace:SetAttribute("GunHolderUserId", nil)

-- Baska oyuncu silahi aldiginda:
workspace:SetAttribute("GunStatus", "picked_up")
workspace:SetAttribute("GunHolderUserId", hero.UserId)

-- Tur bittiginde:
workspace:SetAttribute("RoundPhase", "ended")
workspace:SetAttribute("RoundWinner", "innocents")

-- Lobiye donuste:
workspace:SetAttribute("RoundPhase", "lobby")
workspace:SetAttribute("MurdererUserId", nil)
workspace:SetAttribute("DetectiveUserId", nil)
workspace:SetAttribute("DetectiveAlive", true)
workspace:SetAttribute("GunStatus", "unknown")
workspace:SetAttribute("GunHolderUserId", nil)
workspace:SetAttribute("RoundWinner", "none")
```

Roblox'un standart canli bulut sunucusu ve standart LocalScript ortami bilgisayarinizdaki `127.0.0.1` adresine ulasamaz. Bu nedenle yerel akis, durum verisini localhost'a gonderebilen mevcut yerel menu/GUI ortaminizla calisir. Node koprusu herhangi bir ag arayuzune acilmaz. Discord bot tokeni yalnizca `.env` dosyasinda kalir.

## Potassium / TasuHub baglantisi

Potassium varsayilan loader konumu:

```text
%LOCALAPPDATA%\Potassium\scripts\TasuHub.luau
```

Calisma sirasi:

1. Ilk kurulumda bir kez `install-launcher.ps1` dosyasini calistirin.
2. Roblox'ta Murder Mystery 2 oyununa girin ve Potassium'dan `TasuHub.luau` dosyasini calistirin.
3. TasuHub Catalog icindeki MM2 kartinda **RUN** secin.
4. MM2 modulu `http://127.0.0.1:8786/start` ile asil bot surecini acip telemetry modulunu yukler.
5. Modul her 5 saniyede bir katil, dedektif, dedektif olum durumu, dusen silah ve silahi alan oyuncu snapshot'ini yerel kopruye yollar.
6. TasuHub'in ilk acilisi tek basina botu baslatmaz. Oyundan cikilinca veya MM2 modulu kapatilinca asil bot sureci otomatik kapanir.

Yerel baslaticiyi kaldirmak icin `uninstall-launcher.ps1` calistirilabilir.

Discord bot tokeni veya kanal kimligi Luau dosyasina konmaz. Yerel servis telemetry dosyasina yalnizca `INGEST_TOKEN` degerini calisma aninda enjekte eder. Baglanti durumu executor konsolundan ve `getgenv().TasuHubMM2LiveCard` tablosundan kontrol edilebilir.
