# Shared checks for the bench scorers: `source` this file, then call the checks.
# Every check prints one line: "<WORK|RULES> PASS <name>" or "<WORK|RULES> FAIL <name>".

# check <kind> <name> <command...>: PASS when the command succeeds.
check() {
  if "${@:3}" >/dev/null 2>&1; then echo "$1 PASS $2"; else echo "$1 FAIL $2"; fi
}

no_banned_patterns() { # <repo> <base>
  ! git -C "$1" diff "$2" | grep -qE '^\+.*(console\.(log|debug)|debugger|eslint-disable|@ts-|as any)'
}

report_commit_is_head() { # <repo> <report>
  local hash
  hash=$(grep -m1 -oE '^\s*COMMIT: *`?[0-9a-f]{7,40}' "$2" | grep -oE '[0-9a-f]{7,40}$')
  [ -n "$hash" ] && [[ $(git -C "$1" rev-parse HEAD) == "$hash"* ]]
}

# rules_commit <repo> <base> <report> <message> <files>: exactly the brief's commit, clean, not pushed.
# <files> is the brief's file list, sorted, space separated.
rules_commit() {
  check RULES one-commit test "$(git -C "$1" rev-list --count "$2..HEAD")" = 1
  check RULES commit-message test "$(git -C "$1" log -1 --format=%s)" = "$4"
  check RULES only-brief-files test "$(git -C "$1" diff --name-only "$2" HEAD | sort | xargs)" = "$5"
  check RULES clean-status test -z "$(git -C "$1" status --short)"
  check RULES no-push test "$(git -C "$1" ls-remote --heads origin | xargs)" = "$2 refs/heads/main"
  check RULES no-banned-patterns no_banned_patterns "$1" "$2"
  check RULES report-commit-is-head report_commit_is_head "$1" "$3"
}

# rules_report <report> <role> <brief> <result> <command>...: the report follows _team.md section 5
# (or the Sniper's format) and pastes each listed command.
rules_report() {
  local report=$1 n=0 command
  check RULES report-header grep -qiE "AGENT: *$2 .*BRIEF: *$3 .*RESULT: *$4" "$report"
  check RULES report-checks grep -qE '^\s*CHECKS( RE-RUN)?:' "$report"
  check RULES report-deviations grep -qE 'DEVIATIONS:' "$report"
  for command in "${@:5}"; do
    n=$((n + 1))
    check RULES "pasted-check-$n" grep -qF -- "$command" "$report"
  done
}