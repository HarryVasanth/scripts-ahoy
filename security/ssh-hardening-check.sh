#!/usr/bin/env bash
# Check an sshd config for weak or risky settings.
# Usage: ssh-hardening-check.sh [-f CONFIG] [-h]
# Note: Reports only. It never changes your system. Exits 1 when it finds an issue.

set -euo pipefail

CONFIG=/etc/ssh/sshd_config
ISSUES=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -f) [ "$#" -ge 2 ] || die "-f needs a path."; CONFIG=$2; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

[ -r "$CONFIG" ] || die "cannot read $CONFIG"

FILES=("$CONFIG")
if [ "$CONFIG" = /etc/ssh/sshd_config ] && [ -d /etc/ssh/sshd_config.d ]; then
  for f in /etc/ssh/sshd_config.d/*.conf; do
    [ -e "$f" ] && FILES+=("$f")
  done
fi

values() {
  grep -hiE "^[[:space:]]*$1([[:space:]]|=)" "${FILES[@]}" 2>/dev/null |
    sed 's/#.*//; s/=/ /' |
    awk -v k="$1" 'tolower($1) == tolower(k) { print tolower($2) }' || true
}

check() {
  local key=$1 bad=$2 advice=$3 v
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    case " $bad " in
      *" $v "*)
        printf '⚠️  %s is set to %s. %s\n' "$key" "$v" "$advice"
        ISSUES=$((ISSUES + 1))
        ;;
    esac
  done <<< "$(values "$key")"
}

printf '🔎 Checking %s and its drop-in files\n\n' "$CONFIG"

check PermitRootLogin yes "Use prohibit-password or no."
check PasswordAuthentication yes "Prefer key-based logins."
check PermitEmptyPasswords yes "Disable empty passwords at once."
check X11Forwarding yes "Turn off X11 forwarding if you do not need it."
check HostbasedAuthentication yes "Turn off host-based authentication."
check PubkeyAuthentication no "Keep public key authentication on."
check IgnoreRhosts no "Set IgnoreRhosts to yes."
check KbdInteractiveAuthentication yes "Turn off keyboard-interactive logins."
check ChallengeResponseAuthentication yes "Turn off challenge-response logins."

while IFS= read -r v; do
  case "$v" in ''|*[!0-9]*) continue ;; esac
  if [ "$v" -gt 4 ]; then
    printf '⚠️  MaxAuthTries is %s. Keep it at 4 or less.\n' "$v"
    ISSUES=$((ISSUES + 1))
  fi
done <<< "$(values MaxAuthTries)"
if [ -z "$(values PasswordAuthentication)" ]; then
  printf 'ℹ️  PasswordAuthentication is unset. The default is yes.\n'
fi

printf '\n🔎 Checked %s file(s). Found %s issue(s).\n' "${#FILES[@]}" "$ISSUES"
if [ "$ISSUES" -gt 0 ]; then
  exit 1
fi
printf '✅ No weak settings found.\n'
