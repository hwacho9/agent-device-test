#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$ROOT"
pr_number="${1:-}"
[[ "$pr_number" =~ ^[0-9]+$ ]] || { echo 'Usage: publish-pr-evidence.sh <PR_NUMBER>' >&2; exit 2; }
gh auth status >/dev/null 2>&1 || { echo 'BLOCKER: GitHub CLI 인증 필요' >&2; echo 'USER ACTION: gh auth login' >&2; exit 3; }
repository="${GITHUB_REPOSITORY:-$(gh repo view --json nameWithOwner --jq .nameWithOwner)}"
head_repository="$(gh api "repos/$repository/pulls/$pr_number" --jq .head.repo.full_name)"
[[ "$head_repository" == "$repository" ]] || { echo "Refusing PR write: fork head is $head_repository" >&2; exit 4; }
mkdir -p artifacts/pr
python3 scripts/report/generate_pr_summary.py --output artifacts/pr/pr-summary.md
gh pr comment --help > artifacts/pr/gh-pr-comment-help.txt
printf '%s\n' \
    'Android PNG: NOT ATTACHED (CLI/API file upload unsupported; workflow artifact fallback)' \
    'Android MP4: NOT ATTACHED (CLI/API file upload unsupported; workflow artifact fallback)' \
    'iOS PNG: NOT ATTACHED (CLI/API file upload unsupported; workflow artifact fallback)' \
    'iOS MP4: NOT ATTACHED (CLI/API file upload unsupported; workflow artifact fallback)' \
    'HTML: NOT ATTACHED' > artifacts/pr/attachment-status.txt
if [[ "${GITHUB_ACTIONS:-}" == true ]]; then
    login='github-actions[bot]'
else
    login="$(gh api user --jq .login)"
fi
comments="$(mktemp)"
payload="$(mktemp)"
trap 'rm -f "$comments" "$payload"' EXIT
gh api "repos/$repository/issues/$pr_number/comments" --paginate > "$comments"
comment_id="$(python3 - "$comments" "$login" <<'PY'
import json,sys
marker='<!-- agent-device-mobile-e2e-report -->'
comments=json.load(open(sys.argv[1]))
matches=[item for item in comments if item.get('user',{}).get('login')==sys.argv[2] and marker in item.get('body','')]
print(matches[-1]['id'] if matches else '')
PY
)"
python3 - artifacts/pr/pr-summary.md "$payload" <<'PY'
import json,sys
json.dump({'body':open(sys.argv[1]).read()},open(sys.argv[2],'w'))
PY
if [[ -n "$comment_id" ]]; then
    gh api --method PATCH "repos/$repository/issues/comments/$comment_id" --input "$payload" --jq .html_url | tee artifacts/pr/comment-url.txt
    echo "Updated marker comment $comment_id"
else
    gh pr comment "$pr_number" --repo "$repository" --body-file artifacts/pr/pr-summary.md | tee artifacts/pr/comment-url.txt
fi
