# SYS.MATRIX

Phosphor / operator-terminal watch face for Garmin **fēnix 8**.

Inspired by the digital-rain look from *The Matrix*. **Not affiliated with, endorsed by, or derived from Warner Bros. or The Matrix franchise.** Original code and assets; no movie fonts, stills, or dialogue.

- **Rain** — falling code, time and data on top
- **CRT** — `tty1` window in the rain (Connect IQ settings)
- Time, date, weather (METAR-style), battery %
- AMOLED: rain animates ~10 fps on wrist-raise, dim always-on after timeout
- Solar (MIP): rain animates on wrist-raise, then freezes; screen stays on

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
./build.sh fenix847mm          # 47/51mm AMOLED
./build.sh fenix843mm          # 43mm AMOLED
./build.sh fenix8pro47mm       # Pro / MicroLED
./build.sh fenix8solar51mm     # 51mm Solar
```

Writes `bin/SYS.MATRIX-<device>.prg`. `bin/` and `developer_key` are gitignored.

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

Left buttons, top to bottom: Light, **Menu**, Down.

## Weather

Garmin onboard cache. `--` if it has not synced. Codes: `CLR` `SCT` `BKN` `OVC` `RA` `SN` `TS` `FG`.

## License

MIT for this source. Garmin Connect IQ SDK and device definitions are Garmin’s; this repo does not include them.
