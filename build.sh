#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEVICE="${1:-fenix847mm}"
TAG="${2:-}"
if [[ -n "$TAG" ]]; then
  OUT="${ROOT}/bin/SYS.MATRIX-${TAG}-${DEVICE}.prg"
else
  OUT="${ROOT}/bin/SYS.MATRIX-${DEVICE}.prg"
fi
KEY="${ROOT}/developer_key"
CIQ_HOME="${HOME}/Library/Application Support/Garmin/ConnectIQ"

if [[ -n "${CIQ_SDK:-}" ]]; then
  SDK="$CIQ_SDK"
elif [[ -f "${CIQ_HOME}/current-sdk.cfg" ]]; then
  SDK="$(cat "${CIQ_HOME}/current-sdk.cfg")"
else
  echo "Set CIQ_SDK to your Connect IQ SDK folder (the one that contains bin/monkeyc)." >&2
  exit 1
fi

if [[ ! -d "${CIQ_HOME}/Devices/${DEVICE}" ]]; then
  echo "Missing device definition: ${CIQ_HOME}/Devices/${DEVICE}" >&2
  echo "Open Garmin SdkManager, sign in, and download the Fenix 8 AMOLED device packs." >&2
  echo "Then re-run: ./build.sh ${DEVICE}" >&2
  exit 1
fi

if [[ ! -f "$KEY" ]]; then
  echo "Missing ${KEY}. Generate one with:" >&2
  echo "  openssl genrsa 4096 | openssl pkcs8 -topk8 -inform PEM -outform DER -nocrypt -out developer_key" >&2
  exit 1
fi

export PATH="${SDK}/bin:${PATH}"
mkdir -p "${ROOT}/bin"
echo "SDK=$SDK"
echo "device=$DEVICE"
monkeyc -f "${ROOT}/monkey.jungle" -y "$KEY" -d "$DEVICE" -o "$OUT" -w
echo "wrote $OUT"
echo "sideload: copy that .prg to GARMIN/Apps on the watch (USB storage / MTP), then unplug."
