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
if [[ -n "${EXPECTED_PR_HEAD_SHA:-}" ]]; then
    current_head_sha="$(gh api "repos/$repository/pulls/$pr_number" --jq .head.sha)"
    if [[ "$current_head_sha" != "$EXPECTED_PR_HEAD_SHA" ]]; then
        echo "Skipping obsolete run for $EXPECTED_PR_HEAD_SHA; current PR head is $current_head_sha"
        exit 0
    fi
fi
mkdir -p artifacts/pr
gh pr comment --help > artifacts/pr/gh-pr-comment-help.txt
if [[ "${GITHUB_ACTIONS:-}" == true ]]; then
    login='github-actions[bot]'
else
    login="$(gh api user --jq .login)"
fi
comments="$(mktemp)"
payload="$(mktemp)"
upload_log="artifacts/pr/attachment-upload.log"
attempted_release_tag=''
trap 'rm -f "$comments" "$payload"' EXIT

media_paths=()
media_status=()
add_media() {
    local label="$1"
    shift
    local candidate
    for candidate in "$@"; do
        if [[ -s "$candidate" ]]; then
            media_paths+=("$candidate")
            media_status+=("$label: ATTACHED")
            return
        fi
    done
    media_status+=("$label: NOT GENERATED")
}
if [[ "${GITHUB_ACTIONS:-}" == true ]]; then
    add_media 'Android PNG' artifacts/downloaded/android/runtime/android-final.png
    add_media 'Android MP4' artifacts/downloaded/android/runtime/android-clean-e2e.mp4
    add_media 'iOS PNG' artifacts/downloaded/ios/runtime/ios-final.png
    add_media 'iOS MP4' artifacts/downloaded/ios/runtime/ios-clean-e2e.mp4
else
    add_media 'Android PNG' artifacts/android/runtime/android-final.png
    add_media 'Android MP4' artifacts/android/runtime/android-clean-e2e.mp4
    add_media 'iOS PNG' artifacts/ios/runtime/ios-final.png
    add_media 'iOS MP4' artifacts/ios/runtime/ios-clean-e2e.mp4
fi

write_status() {
    printf '%s\n' "${media_status[@]}" 'HTML: NOT ATTACHED' > artifacts/pr/attachment-status.txt
}

mark_media_failed() {
    local reason="$1"
    local index
    for ((index = 0; index < ${#media_status[@]}; index++)); do
        if [[ "${media_status[$index]}" == *': ATTACHED' ]]; then
            media_status[$index]="${media_status[$index]%: ATTACHED}: FAILED ($reason)"
        elif [[ "${media_status[$index]}" == *': UPLOADED' ]]; then
            media_status[$index]="${media_status[$index]%: UPLOADED}: FAILED ($reason)"
        fi
    done
}

refresh_comments() {
    gh api "repos/$repository/issues/$pr_number/comments?per_page=100" --paginate --slurp > "$comments"
}

latest_marker() {
    python3 - "$comments" "$login" <<'PY'
import json,sys
marker='<!-- agent-device-mobile-e2e-report -->'
pages=json.load(open(sys.argv[1]))
comments=[item for page in pages for item in page]
matches=[item for item in comments if item.get('user',{}).get('login')==sys.argv[2] and marker in item.get('body','')]
if matches:
    item=matches[-1]
    print(f"{item['id']}\t{item['html_url']}")
PY
}

delete_older_markers() {
    local keep_id="$1"
    [[ -n "$keep_id" ]] || return 1
    python3 - "$comments" "$login" "$keep_id" <<'PY' | while IFS= read -r old_id; do
import json,sys
marker='<!-- agent-device-mobile-e2e-report -->'
for page in json.load(open(sys.argv[1])):
  for item in page:
    if item.get('user',{}).get('login')==sys.argv[2] and marker in item.get('body','') and str(item['id']) != sys.argv[3]:
        print(item['id'])
PY
        gh api --method DELETE "repos/$repository/issues/comments/$old_id" >/dev/null || return
    done
}

cleanup_old_releases() {
    local release_prefix="$1"
    local keep_tag="${2:-}"
    local current_run_id="${GITHUB_RUN_ID:-}"
    local current_attempt="${GITHUB_RUN_ATTEMPT:-1}"
    local release_list="artifacts/pr/releases.json"
    local old_release_tags="artifacts/pr/old-release-tags.txt"
    publish_stage='clean older PR evidence releases'
    rm -f "$release_list" "$old_release_tags"
    if ! gh release list --repo "$repository" --limit 100 --json tagName > "$release_list"; then
        echo 'WARNING: could not list older PR evidence releases' >&2
        return 0
    fi
    if ! python3 - "$release_list" "$release_prefix" "$keep_tag" "$current_run_id" "$current_attempt" > "$old_release_tags" <<'PY'
import json,re,sys
current_key=(int(sys.argv[4]), int(sys.argv[5])) if sys.argv[4].isdigit() and sys.argv[5].isdigit() else None
pattern=re.compile(rf'^{re.escape(sys.argv[2])}-(\d+)-attempt-(\d+)$')
for item in json.load(open(sys.argv[1])):
    tag=item.get('tagName','')
    match=pattern.fullmatch(tag)
    if (tag != sys.argv[2] and not match) or tag == sys.argv[3]:
        continue
    if current_key and match and (int(match.group(1)), int(match.group(2))) >= current_key:
        continue
    print(tag)
PY
    then
        echo 'WARNING: could not identify older PR evidence releases' >&2
        return 0
    fi
    while IFS= read -r old_tag; do
        [[ -n "$old_tag" ]] || continue
        if ! gh release delete "$old_tag" --repo "$repository" --cleanup-tag --yes; then
            echo "WARNING: could not remove older evidence release $old_tag" >&2
        fi
    done < "$old_release_tags"
    return 0
}

write_payload() {
    python3 - artifacts/pr/pr-summary.md "$payload" <<'PY'
import json,sys
json.dump({'body':open(sys.argv[1]).read()},open(sys.argv[2],'w'))
PY
}

publish_fallback() {
    local mode="$1"
    shift
    python3 scripts/report/generate_pr_summary.py --attachment-mode "$mode" --output artifacts/pr/pr-summary.md "$@" || return
    write_payload || return
    refresh_comments || return
    local marker_info comment_id comment_url
    marker_info="$(latest_marker)" || return
    if [[ -n "$marker_info" ]]; then
        IFS=$'\t' read -r comment_id comment_url <<< "$marker_info"
        gh api --method PATCH "repos/$repository/issues/comments/$comment_id" --input "$payload" --jq .html_url | tee artifacts/pr/comment-url.txt || return
    else
        gh pr comment "$pr_number" --repo "$repository" --body-file artifacts/pr/pr-summary.md | tee artifacts/pr/comment-url.txt || return
        refresh_comments || return
        marker_info="$(latest_marker)" || return
        [[ -n "$marker_info" ]] || return 1
        IFS=$'\t' read -r comment_id comment_url <<< "$marker_info"
    fi
    refresh_comments || return
    marker_info="$(latest_marker)" || return
    [[ -n "$marker_info" ]] || return 1
    IFS=$'\t' read -r comment_id comment_url <<< "$marker_info"
    [[ -n "$comment_id" ]] || return 1
    delete_older_markers "$comment_id" || return
}

publish_release_assets() {
    local release_prefix="pr-$pr_number-mobile-e2e-evidence"
    local publication_id="${GITHUB_RUN_ID:-local}-attempt-${GITHUB_RUN_ATTEMPT:-1}"
    local release_tag="$release_prefix-$publication_id"
    local default_branch release_json media_urls_json
    if (( ${#media_paths[@]} == 0 )); then
        write_status || return
        publish_stage='publish PR marker comment without media'
        publish_fallback none || return
        cleanup_old_releases "$release_prefix"
        return 0
    fi
    publish_stage='resolve default branch'
    default_branch="$(gh api "repos/$repository" --jq .default_branch)" || return
    release_json="artifacts/pr/release.json"
    media_urls_json="artifacts/pr/media-urls.json"
    rm -f "$release_json" "$media_urls_json"

    publish_stage='create release and upload assets'
    attempted_release_tag="$release_tag"
    gh release create "$release_tag" "${media_paths[@]}" --repo "$repository" \
        --target "$default_branch" \
        --title "PR #$pr_number mobile E2E evidence · run ${GITHUB_RUN_ID:-local}" \
        --notes "PNG/MP4 evidence for PR #$pr_number. Local HTML is not uploaded." \
        --prerelease --latest=false || return

    publish_stage='verify release assets'
    gh release view "$release_tag" --repo "$repository" --json assets,url > "$release_json" || return
    python3 - "$release_json" "$media_urls_json" "${media_paths[@]}" <<'PY' || return
import json,sys
from pathlib import Path
release=json.load(open(sys.argv[1]))
available={item['name']: item['url'] for item in release.get('assets', [])}
expected=[Path(value).name for value in sys.argv[3:]]
missing=[name for name in expected if name not in available]
if missing:
    raise SystemExit(f"Release upload missing assets: {', '.join(missing)}")
json.dump({name: available[name] for name in expected}, open(sys.argv[2], 'w'))
PY
    [[ -s "$media_urls_json" ]] || return 1
    media_status=()
    add_release_status() {
        local label="$1" filename="$2"
        if python3 - "$media_urls_json" "$filename" <<'PY'
import json,sys
raise SystemExit(0 if sys.argv[2] in json.load(open(sys.argv[1])) else 1)
PY
        then
            media_status+=("$label: UPLOADED")
        else
            media_status+=("$label: NOT GENERATED")
        fi
    }
    add_release_status 'Android PNG' android-final.png
    add_release_status 'Android MP4' android-clean-e2e.mp4
    add_release_status 'iOS PNG' ios-final.png
    add_release_status 'iOS MP4' ios-clean-e2e.mp4
    local release_url
    release_url="$(gh release view "$release_tag" --repo "$repository" --json url --jq .url)" || return
    printf '%s\n' "$release_url" > artifacts/pr/release-url.txt
    write_status || return
    if [[ -n "${EXPECTED_PR_HEAD_SHA:-}" ]]; then
        local current_head_sha
        current_head_sha="$(gh api "repos/$repository/pulls/$pr_number" --jq .head.sha)" || return
        if [[ "$current_head_sha" != "$EXPECTED_PR_HEAD_SHA" ]]; then
            echo "Discarding obsolete evidence for $EXPECTED_PR_HEAD_SHA; current PR head is $current_head_sha"
            gh release delete "$release_tag" --repo "$repository" --cleanup-tag --yes >/dev/null 2>&1 || \
                echo "WARNING: could not remove obsolete evidence release $release_tag" >&2
            attempted_release_tag=''
            return 0
        fi
    fi
    publish_stage='publish PR marker comment'
    publish_fallback release --media-urls-json "$media_urls_json" --release-url "$release_url" || return

    cleanup_old_releases "$release_prefix" "$release_tag"
    return 0
}

if [[ "${PR_MEDIA_MODE:-attachment}" == release ]]; then
    publish_stage='publish release evidence'
    if publish_release_assets; then
        exit 0
    fi
    if [[ -n "$attempted_release_tag" ]]; then
        gh release delete "$attempted_release_tag" --repo "$repository" --cleanup-tag --yes >/dev/null 2>&1 || \
            echo "WARNING: could not remove incomplete evidence release $attempted_release_tag" >&2
    fi
    mark_media_failed "$publish_stage failed; workflow artifact fallback"
    write_status
    publish_fallback failed
    echo "GitHub evidence publication failed during: $publish_stage" >&2
    exit 8
fi

if [[ "${PR_ATTACHMENTS:-enabled}" == disabled ]]; then
    mark_media_failed 'direct attachment publisher unavailable; workflow artifact fallback'
    write_status
    publish_fallback failed
    exit 0
fi

if ! grep -q -- '--attach' artifacts/pr/gh-pr-comment-help.txt; then
    mark_media_failed 'GitHub CLI 2.99.0 or newer required'
    write_status
    publish_fallback failed
    echo 'BLOCKER: GitHub CLI 2.99.0 or newer is required for --attach' >&2
    exit 5
fi

python3 scripts/report/generate_pr_summary.py --attachment-mode attach --output artifacts/pr/pr-summary.md
attach_args=()
for path in "${media_paths[@]}"; do
    attach_args+=(--attach "$path")
done

if gh pr comment "$pr_number" --repo "$repository" --body-file artifacts/pr/pr-summary.md "${attach_args[@]}" >"$upload_log" 2>&1; then
    cat "$upload_log"
    write_status
    refresh_comments
    marker_info="$(latest_marker)"
    [[ -n "$marker_info" ]] || { echo 'Attachment comment was not found after publishing' >&2; exit 6; }
    IFS=$'\t' read -r comment_id comment_url <<< "$marker_info"
    printf '%s\n' "$comment_url" | tee artifacts/pr/comment-url.txt
    delete_older_markers "$comment_id"
    exit 0
fi

cat "$upload_log" >&2
mark_media_failed 'see attachment-upload.log; workflow artifact fallback'
write_status
publish_fallback failed
echo 'Direct attachment upload failed; the PR summary points to workflow artifacts.' >&2
exit 7
