#!/usr/bin/env bash
set -euo pipefail

# Audits local accounts for weak or risky settings.
# Usage: user-audit [-h]
# Needs: awk, /etc/passwd
# Note: the password check needs root to read /etc/shadow.

if [[ $(uname -s) != Linux ]]; then
  printf 'Error: this tool needs Linux.\n' >&2
  exit 1
fi

if [[ ! -r /etc/passwd ]]; then
  printf 'Error: /etc/passwd is not readable.\n' >&2
  exit 1
fi

show_help() {
  cat <<'EOF'
user-audit - audit local accounts.
Usage: user-audit
Checks:
  - accounts with user ID 0 (root level)
  - accounts that can log in
  - accounts with an empty password
  - members of the sudo or wheel group

Run it with sudo to include the password check.
EOF
}

for arg in "$@"; do
  case "$arg" in
    -h | --help) show_help; exit 0 ;;
    *)
      printf 'Error: unknown argument: %s\n' "$arg" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

findings=0

printf 'Accounts with user ID 0:\n'
roots=$(awk -F: '$3 == 0 {print "  " $1}' /etc/passwd)
printf '%s\n' "$roots"
root_count=$(printf '%s\n' "$roots" | grep -c . || true)
if [[ $root_count -gt 1 ]]; then
  printf '❌ More than one root-level account exists.\n'
  findings=$((findings + 1))
fi

printf '\nAccounts that can log in:\n'
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ && $7 != "" {printf "  %-16s %s\n", $1, $7}' /etc/passwd
printf '  (system accounts with a real shell need a close look.)\n'

printf '\nAccounts with an empty password:\n'
if [[ -r /etc/shadow ]]; then
  empty=$(awk -F: '$2 == "" {print "  " $1}' /etc/shadow)
  if [[ -z "$empty" ]]; then
    printf '  None.\n'
  else
    printf '%s\n' "$empty"
    printf '❌ An account without a password exists.\n'
    findings=$((findings + 1))
  fi
else
  printf '  Skipped. Run with sudo to read /etc/shadow.\n'
fi

printf '\nAdministrator group members:\n'
admin=$(getent group sudo wheel 2>/dev/null | awk -F: '$4 != "" {print "  " $1 ": " $4}')
printf '%s\n' "${admin:-  None.}"
printf '  Keep this list small.\n'

if [[ $findings -gt 0 ]]; then
  printf '\n⚠️  %s serious finding(s).\n' "$findings"
fi
