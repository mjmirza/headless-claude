#!/usr/bin/env bash
# Exercise the shell library with stand-in binaries. No live CLI and no
# privileged user switch are required.
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
    printf 'jq is required\n' >&2
    exit 1
fi

if ! command -v timeout >/dev/null 2>&1; then
    printf 'timeout is required\n' >&2
    exit 1
fi

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "${tmp}"' EXIT

bin="${tmp}/bin"
mkdir -p "${bin}"

cat > "${bin}/su" << 'EOF'
#!/bin/sh
while [ $# -gt 0 ]; do
    if [ "$1" = "-c" ]; then
        shift
        exec sh -c "$1"
    fi
    shift
done
printf 'su stand-in: missing -c\n' >&2
exit 1
EOF

cat > "${bin}/claude" << 'EOF'
#!/bin/sh
if [ -n "${STUB_DIR:-}" ]; then
    rec=$(mktemp "${STUB_DIR}/call.XXXXXX")
    printf '%s\n' "$*" > "${rec}"
fi
case " $* " in
    *" --output-format json "*)
        printf '%s\n' '{"result":"ok"}'
        ;;
    *)
        printf '%s\n' 'plain text'
        ;;
esac
EOF

chmod +x "${bin}/su" "${bin}/claude"

export PATH="${bin}:${PATH}"
export CLAUDE_BINARY="${bin}/claude"
export CLAUDE_USER="library-test"
export CLAUDE_LOG_DIR="${tmp}/logs"
export CLAUDE_CONFIG_DIR="${tmp}/config"
export CLAUDE_RETRY_COUNT=1
export CLAUDE_RETRY_DELAY=0
export CLAUDE_TIMEOUT=10

# shellcheck disable=SC1091
source "${root}/lib/claude-headless.sh"

if [[ "$(command -v su)" != "${bin}/su" ]]; then
    printf 'PATH did not prefer the su stand-in: %s\n' "$(command -v su)" >&2
    exit 1
fi

failures=0

count_format() {
    local rest="$1"
    local count=0
    while [[ "${rest}" == *"--output-format"* ]]; do
        rest="${rest#*"--output-format"}"
        count=$((count + 1))
    done
    printf '%s\n' "${count}"
}

note_fail() {
    printf 'FAIL: %s\n' "$*" >&2
    failures=$((failures + 1))
}

log_file="${CLAUDE_LOG_DIR}/claude-headless-$(date '+%Y%m%d').log"

# Captured stdout is the command result. Status text stays on stderr and in the log file.
export STUB_DIR="${tmp}/calls-capture"
mkdir -p "${STUB_DIR}"
capture_err="${tmp}/capture.err"
capture_out=$(claude_exec_capture "ping" 2>"${capture_err}")
if [[ "${capture_out}" == "plain text" ]]; then
    printf 'ok: capture stdout is only the command result\n'
else
    note_fail "capture stdout was $(printf '%q' "${capture_out}")"
fi
if [[ -f "${log_file}" ]] && grep -q 'Executing Claude with output capture' "${log_file}"; then
    printf 'ok: capture still writes the log file\n'
else
    note_fail "log file is missing the capture line"
fi
if grep -q '\[INFO\]' "${capture_err}"; then
    printf 'ok: capture status text is on stderr\n'
else
    note_fail "stderr did not receive the capture status line"
fi
capture_args=$(cat "${STUB_DIR}"/*)
if [[ "${capture_args}" != *"--output-format"* ]]; then
    printf 'ok: plain capture does not force a format\n'
else
    note_fail "plain capture passed a format: ${capture_args}"
fi

# JSON helper asks for JSON when the caller did not, and prints only that object.
export STUB_DIR="${tmp}/calls-json"
mkdir -p "${STUB_DIR}"
json_err="${tmp}/json.err"
json_status=0
json_out=$(claude_exec_json "ping-json" 2>"${json_err}") || json_status=$?
if [[ "${json_status}" -eq 0 ]] && printf '%s\n' "${json_out}" | jq -e '.result == "ok"' >/dev/null; then
    printf 'ok: json helper returns a JSON object\n'
else
    note_fail "json helper status ${json_status}, stdout $(printf '%q' "${json_out}")"
fi
json_args=$(cat "${STUB_DIR}"/*)
json_formats=$(count_format "${json_args}")
if [[ "${json_formats}" -eq 1 && "${json_args}" == *"--output-format json"* ]]; then
    printf 'ok: json helper requests json once\n'
else
    note_fail "expected one json format flag, got ${json_formats} in: ${json_args}"
fi

# An explicit format is left as the caller wrote it.
export STUB_DIR="${tmp}/calls-json-explicit"
mkdir -p "${STUB_DIR}"
explicit_status=0
explicit_out=$(claude_exec_json "ping-explicit" "--max-turns 2 --output-format json" 2>/dev/null) || explicit_status=$?
explicit_args=$(cat "${STUB_DIR}"/*)
explicit_formats=$(count_format "${explicit_args}")
if [[ "${explicit_status}" -eq 0 && "${explicit_formats}" -eq 1 && "${explicit_out}" == '{"result":"ok"}' ]]; then
    printf 'ok: explicit output format is unchanged\n'
else
    note_fail "explicit format status ${explicit_status}, flags ${explicit_formats}, args: ${explicit_args}"
fi

# Errexit must stay enabled. A conditional would hide the counter bug.
export STUB_DIR="${tmp}/calls-parallel"
mkdir -p "${STUB_DIR}"
# Passed by name into the nameref inside claude_exec_parallel_agents.
# shellcheck disable=SC2034
work=(
    "explore|one|alpha task|haiku"
    "plan|two|beta task|sonnet"
)
set +e
(
    set -e
    claude_exec_parallel_agents work 1 >/dev/null
)
parallel_status=$?
set -e
if [[ "${parallel_status}" -ne 0 ]]; then
    note_fail "parallel run exited ${parallel_status}"
else
    found_alpha=0
    found_beta=0
    for recorded in "${STUB_DIR}"/*; do
        content=$(cat "${recorded}")
        if [[ "${content}" == *"alpha task"* && "${content}" == *"--model haiku"* ]]; then
            found_alpha=1
        fi
        if [[ "${content}" == *"beta task"* && "${content}" == *"--model sonnet"* ]]; then
            found_beta=1
        fi
    done
    if [[ "${found_alpha}" -eq 1 && "${found_beta}" -eq 1 ]]; then
        printf 'ok: parallel run executed both tasks\n'
    else
        note_fail "parallel tasks missing (alpha=${found_alpha} beta=${found_beta})"
    fi
fi

if [[ "${failures}" -ne 0 ]]; then
    printf '%s check(s) failed\n' "${failures}" >&2
    exit 1
fi

printf 'library smoke tests passed\n'
