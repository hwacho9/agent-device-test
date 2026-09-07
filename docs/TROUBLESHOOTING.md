# Troubleshooting

- Default Java is 11: use the Bash scripts, which select installed Temurin 17.
- CoreSimulator connection invalid / Emulator neon error inside Codex sandbox:
  execute the authorized device command with desktop sandbox escalation. Do not
  infer that the installed Simulator runtime or physical CPU is missing.
- avdmanager reports no image although it is installed: command-line tools must
  be in the SDK's canonical cmdline-tools/<version> directory.
- Android command-line tools 23 delegates sdkmanager to the new Android CLI.
  Installation logs can remain at the download URL while a large image downloads.
- SDK XML version warning from AGP: record the warning; distinguish it from a
  task failure. Do not rewrite SDK metadata or upgrade all tools to hide it.
- Xcode/KMP: local Xcode is 26.6, while the Kotlin compatibility matrix lists 26.4.
  Framework compilation passed; full app integration remains a separate gate.
- Missing visual references: validation must fail; run the explicit reference
  recording operation and inspect changes. Never auto-record during validation.
- E2E failure: retain step, expected state, observed state, screenshot and logs.
  A failed step must not print PASS or be silently skipped.
- agent-device 0.20.10 Android helper omits native checked state from its node
  schema. The app shows a user-facing On/Off indicator (profile.reminder.state)
  bound to the same immutable ProfileState boolean as the Switch. Replay asserts
  this indicator after toggling, rather than merely checking that the control is
  enabled. Concurrent standalone uiautomator dump can be killed while the helper
  instrumentation owns accessibility, so runtime replay does not mix them.
- SwiftUI Toggle with a visible label exposes an accessibility container spanning
  the entire row. A coordinate-center press of that identifier can be a no-op.
  The app uses a separate visible label plus labelsHidden on the native Toggle,
  keeping the automation identifier on the actual switch bounds.
- npm audit (2026-09-07) reports 3 advisories in agent-device's dependency tree:
  undici high; @limrun/api and agent-device moderate. These are dev-tool
  dependencies, not packaged in the Android/iOS apps. npm's suggested fix is a
  downgrade to agent-device 0.13.3, so no force-fix/downgrade was applied to the
  verified 0.20.10 CLI. See artifacts/environment/npm-audit.json. Cloud providers
  are outside this local demo and are not used.
