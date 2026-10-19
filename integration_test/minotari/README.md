# XTM integration tests

Cake's shared create/restore suites already iterate over enabled wallet types.
`CommonTestFlows.getWalletSeedsByWalletType` now supplies XTM's public disposable
fixture, so restore no longer silently skips this currency. The shared suites
retain their default network behavior; a Tari mnemonic does not encode a network.

The dedicated mobile suite covers the same core cases on **Esmeralda**:

- Create through Cake's normal screens and real native wallet service; check the
  network, 24-word seed, address and zero balance.
- Reopen the encrypted wallet and compare its seed/address/network.
- Restore the public fixture through Cake's restore screens; compare its full
  expected Esmeralda address and zero balance.
- Insert a controlled credit of 2.500001 XTM into the isolated native ledger,
  read it through the real Rust bridge, and assert the actual Home balance card.

The controlled credit tests native-to-UI balance display. It does not prove live
scanning or receipt of a chain transaction. These cases do not send funds.
The fixture seed is intentionally public and must never hold funds.

The suite reuses `CommonTestFlows` and the existing page robots. Its small XTM
subclass confirms PIN setup using the actual localized OK button: the existing
shared helper expects an alert button key that the current alert widget does not
forward. This suite does not change the common alert or other currencies' tests.

Each run uses a fresh temporary directory and in-memory preferences/secure
storage. It does not reset the normal profile or enter its PIN. A test-only wallet
service selects Esmeralda; the native wallet, app view models, screens, and
encrypted file operations are real. XTM's configured node is loopback port 1:
network synchronization is not part of these deterministic cases.

## Running on iOS

Build the native library for Esmeralda first. A mainnet library must fail the
network guard; do not disable that guard to run tests.

```sh
# Prepare the current UI assets if this checkout has not compiled them yet.
dart run vector_graphics_compiler --input-dir assets/images --out-dir assets/images
bash compile_graphics.sh

bash scripts/ios/build_minotari.sh esmeralda
# Get device-type/runtime identifiers from xcrun simctl list devicetypes/runtimes.
bash scripts/ios/test_minotari.sh <device-type-id> <ios-runtime-id>
```

The launcher creates and later deletes its own disposable Simulator. It does not
accept an existing Simulator/device ID. It passes `--keep-app-running` because
Flutter drive's default teardown **uninstalls the app and deletes its container**;
path/preferences isolation inside Dart does not protect against that uninstall.
Do not run the target against a device containing personal wallets.

The opt-in flag and separate directory keep this target out of the runner's
default multi-currency/mainnet suite. On Android, use an Android Esmeralda native
build and a dedicated disposable emulator/device. Pass `--keep-app-running` to
Flutter drive there too. The development workspace's `integration.md` records
validation results.

The shared helper also references the other currencies' existing generated
`*TestWalletSeeds` constants in `lib/.secrets.g.dart`; the file must provide them
even when only XTM executes. No other currency's real seed is needed for this run.
Compiled `.vec` assets, generated secrets, frameworks and test response output
are build artifacts, not part of the XTM test source change.

After testing, rebuild the native library for the network of the ordinary app
(normally `bash scripts/ios/build_minotari.sh mainnet`) and rebuild/relaunch the
normal `lib/main.dart` entrypoint. Do not launch a normal mainnet wallet with the
temporary Esmeralda library.
