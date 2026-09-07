# agent-device runbook

Use agent-device 0.20.10, pinned locally in package-lock.json. Bash scripts put
node_modules/.bin on PATH, and select the verified Node 24.19.0 runtime when the
shell Node is too old. This is the real CLI, not an alias or replacement wrapper.
On another computer, install a supported Node >=22.12 and run `npm ci`.

```sh
source scripts/env.sh
agent-device --version
agent-device help
agent-device doctor
```

## Ownership and iOS prepare
The installed CLI creates a temporary daemon for bare replay unless a state
directory is explicit. scripts/env.sh sets AGENT_DEVICE_STATE_DIR so prepare,
replay and final snapshot verification share one daemon and runner lease.
Do not stop another task's daemon to steal a device. The default sessions are
demo-android and demo-ios. Android uses --serial; iOS uses --udid. --device is
for a device name, not its ID.

Required order: Simulator boot, app installation, prepare ios-runner, first
snapshot/replay. prepare-ios-agent-device.sh checks installation before prepare.

## Exploration
```sh
bash scripts/explore-android-e2e.sh
bash scripts/explore-ios-e2e.sh
```
These scripts reset/open and arm a unique recording under runtime/explorations.
They intentionally bootstrap a live Codex exploration: Codex reads the current
snapshot, explains the next action, invokes the actual CLI, and verifies the new
state. A standalone shell script cannot supply new AI decisions. Do not describe
these bootstraps or a deterministic replay as a completed Agent Pass.

Use full `snapshot` when `snapshot -i` omits non-interactive text. Capture a new
snapshot after navigation. Use current refs or verified stable selectors.
After Saved, assert final snapshot contents, capture a screenshot, `wait` on
`id="profile.saved"`, then `close` to publish the armed recording. Review it
before promoting it into e2e/{platform}/login-profile-save.ad.

## Platform differences
Android's helper omits checked state. The On/Off indicator is bound to exactly
the same shared boolean as the native Switch, and `.ad` asserts that state.
On iOS, the stable ID is on a parent Switch; press its leaf using the recorded
`role="switch" label="0" value="0"` selector, guarded by the verified parent profile.reminder, rather than unstable scroll-decoration ancestry.
Then assert `id="profile.reminder" value="1"`. This avoids fixed coordinates.
`is hidden` requires a matched hidden element: absence of login.error is instead
asserted from the full final JSON snapshot in replay-e2e.py.

## Replay and recording
```sh
bash scripts/replay-android-e2e.sh
bash scripts/replay-ios-e2e.sh
bash scripts/record-android-clean.sh
bash scripts/record-ios-clean.sh
```
The reviewed `.ad` files keep recorded target metadata, use stable selectors,
and wait on screen landmarks. No automatic repair or --save-script is used on
replay. The wrapper checks the scenario hash before/after, final elements,
reminder on, and no error node. Every run gets its own evidence directory.

Recordings use adb screenrecord or simctl io recordVideo around the real replay.
A recording-only .ad copy adds 1.75-second presentation pauses while preserving all
original actions/assertions; the original .ad stays unchanged. Recordings finalize on SIGINT and are decoded with ffmpeg before publishing. Failed
recordings never overwrite the canonical successful clean video.
