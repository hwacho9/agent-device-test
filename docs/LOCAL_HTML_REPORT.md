# Local HTML evidence report

The report combines `artifacts/results/android.json` and `ios.json`. Those JSON
files are written by `run-platform-ci.sh` from process exit codes; HTML is a view,
not a test result source.

```bash
bash scripts/run-platform-ci.sh android
bash scripts/run-platform-ci.sh ios
./scripts/generate-local-report.sh
./scripts/serve-local-report.sh
```

The server binds only `127.0.0.1` and defaults to
`http://127.0.0.1:8080`. If that port is busy, the script prints an alternative:

```bash
LOCAL_REPORT_PORT=8081 ./scripts/serve-local-report.sh
```

The generator creates `artifacts/local-report/index.html` and copies only the
referenced images, videos, and logs into `assets/`. Links are relative. CSS is
inline; there are no external scripts, fonts, CDNs, or network dependencies.
Missing evidence renders as `NOT GENERATED`, never as a broken image or inferred
PASS. A failed result displays the first failed check and its exit code.

The whole output is ignored by Git. CI does not invoke this generator, upload its
HTML as an artifact, publish it to Pages, or attach it to a pull request.

Run the standard-library checks with:

```bash
python3 scripts/report/test_local_report.py
```
