#!/usr/bin/env bash
set -euo pipefail

# Always create our own Simulator. Never accept an existing device or app profile.
if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <simulator-device-type-id> <ios-runtime-id>" >&2
  echo "List identifiers with: xcrun simctl list devicetypes; xcrun simctl list runtimes" >&2
  exit 2
fi

command -v flutter >/dev/null
command -v xcrun >/dev/null
XTM_ROOT=$(cd "$(dirname "$0")/../.." && pwd)
XTM_TEST_DEVICE=$(xcrun simctl create "Cake XTM integration $(date +%s)" "$1" "$2")
cleanup() {
  xcrun simctl shutdown "$XTM_TEST_DEVICE" >/dev/null 2>&1 || true
  xcrun simctl delete "$XTM_TEST_DEVICE" >/dev/null 2>&1 || true
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

xcrun simctl boot "$XTM_TEST_DEVICE"
xcrun simctl bootstatus "$XTM_TEST_DEVICE" -b
cd "$XTM_ROOT"
flutter drive --no-pub --keep-app-running \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/minotari/minotari_wallet_flow_test.dart \
  --dart-define=MINOTARI_ESMERALDA_TESTS=true \
  -d "$XTM_TEST_DEVICE"
