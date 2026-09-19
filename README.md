# SYS.MATRIX

Phosphor / operator-terminal watch face for Garmin **fēnix 8**.

Inspired by the digital-rain look from *The Matrix*. **Not affiliated with, endorsed by, or derived from Warner Bros. or The Matrix franchise.** Original code and assets; no movie fonts, stills, or dialogue.

- **Rain** — falling code (v4 uses a tiny original bitmap “code” font; v3 is Kosugi katakana), time and data on top. Rain draws through `1915`.
- **CRT** — `tty1` window in the rain (Connect IQ settings)
- Time, date, weather (METAR-style), battery %
- AMOLED: rain animates ~10 fps on wrist-raise, dim always-on after timeout
- Solar (MIP): rain animates on wrist-raise, then freezes; screen stays on
- **Glance** (`glance/`) — swipe-up terminal strip: time, battery, weather. Open it for HR and steps too.

## Devices

| Product id | Watch |
|---|---|
| `fenix843mm` | Fenix 8 43mm AMOLED (416×416) |
| `fenix847mm` | Fenix 8 47/51mm AMOLED (454×454) |
| `fenix8pro47mm` | Fenix 8 Pro / MicroLED (454×454) |
| `fenix8solar51mm` | Fenix 8 Solar 51mm MIP (280×280) |

Build **only** the product that matches the watch. An AMOLED `.prg` will not run correctly on Solar, and vice versa.

## Build

Needs [Connect IQ SDK](https://developer.garmin.com/connect-iq/sdk/) 9.x, the matching **device pack** from SdkManager, and JDK 11+ (Java 9 often works).

Generate a **local** signing key (do not commit it):

```bash
openssl genrsa 4096 | openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt -out developer_key
```

```bash
./build.sh fenix847mm v4       # watch face → bin/v4/47.prg
./build.sh fenix8solar51mm v4  # Solar → bin/v4/solar51.prg
./build.sh glance fenix847mm   # glance + full terminal page
```

Versioned builds go in a short folder so they are easy to spot:

| File | Watch |
|---|---|
| `bin/v3/47.prg` | Fenix 8 47/51mm AMOLED (Kosugi katakana rain) |
| `bin/v4/47.prg` | same watch, code-style bitmap rain |
| `bin/v3/43.prg` / `bin/v4/43.prg` | 43mm AMOLED |
| `bin/v3/pro.prg` / `bin/v4/pro.prg` | Fenix 8 Pro |
| `bin/v3/solar51.prg` / `bin/v4/solar51.prg` | 51mm Solar |

Untagged builds still write `bin/SYS.MATRIX-<device>.prg`. `bin/` and `developer_key` are gitignored.

## Install

Fenix 8 uses **MTP**, not a Finder disk on macOS.

1. USB cable. On the watch, if asked, pick **MTP**.  
   If it only charges: hold **middle-left** → Watch Settings → System → Advanced → **USB Mode** → MTP. Replug.
2. Quit Garmin Express.
3. Copy the `.prg` to `GARMIN/Apps`.
   - Windows: the watch appears as a drive.
   - Mac: [OpenMTP](https://openmtp.ganeshrvel.com/).
4. Wait for the copy to finish. Eject. The file vanishing from `Apps` is normal.
5. Clock screen: hold **middle-left** → **Watch Face** → **SYS.MATRIX**.

Glance: after copying `SYS.MATRIX-glance-*.prg`, unplug, then from the clock **press the bottom-left button** (glances) and find **SYS.MATRIX.gl**. Press **START** (top-right) to open the full dump.

Left buttons, top to bottom: Light, **Menu**, Down.

## Weather

Garmin onboard cache. `--` if it has not synced. Codes: `CLR` `SCT` `BKN` `OVC` `RA` `SN` `TS` `FG`.

## License

MIT for this source. Garmin Connect IQ SDK and device definitions are Garmin’s; this repo does not include them.
