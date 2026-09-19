#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="face"
DEVICE="${1:-fenix847mm}"
TAG="${2:-}"
if [[ "${1:-}" == "glance" ]]; then
  APP="glance"
  DEVICE="${2:-fenix847mm}"
  TAG="${3:-}"
fi
short_device() {
  case "$1" in
    fenix847mm) echo "47" ;;
    fenix843mm) echo "43" ;;
    fenix8pro47mm) echo "pro" ;;
    fenix8solar51mm) echo "solar51" ;;
    *) echo "$1" ;;
  esac
}

KEY="${ROOT}/developer_key"
SHORT=""
if [[ "$APP" == "glance" ]]; then
  JUNGLE="${ROOT}/glance/monkey.jungle"
  if [[ -n "$TAG" ]]; then
    OUT="${ROOT}/bin/SYS.MATRIX-glance-${TAG}-${DEVICE}.prg"
    SHORT="${ROOT}/bin/${TAG}/glance-$(short_device "$DEVICE").prg"
  else
    OUT="${ROOT}/bin/SYS.MATRIX-glance-${DEVICE}.prg"
  fi
else
  JUNGLE="${ROOT}/monkey.jungle"
  if [[ -n "$TAG" ]]; then
    OUT="${ROOT}/bin/SYS.MATRIX-${TAG}-${DEVICE}.prg"
    SHORT="${ROOT}/bin/${TAG}/$(short_device "$DEVICE").prg"
  else
    OUT="${ROOT}/bin/SYS.MATRIX-${DEVICE}.prg"
  fi
fi
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
monkeyc -f "$JUNGLE" -y "$KEY" -d "$DEVICE" -o "$OUT" -w
echo "wrote $OUT"
if [[ -n "$SHORT" ]]; then
  mkdir -p "$(dirname "$SHORT")"
  cp "$OUT" "$SHORT"
  echo "wrote $SHORT"
fi
echo "sideload: copy that .prg to GARMIN/Apps on the watch (USB storage / MTP), then unplug."
