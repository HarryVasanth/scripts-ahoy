#!/usr/bin/env bash
# Check key kernel settings for hardening.
# Usage: kernel-hardening.sh [-h]
# Needs: sysctl

set -euo pipefail

BAD=0

die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help) usage; exit 0 ;;
    *) die "unknown option $1" ;;
  esac
done

command -v sysctl >/dev/null 2>&1 || die "sysctl is not installed."

check() {
  local key=$1 want=$2 val
  val=$(sysctl -n "$key" 2>/dev/null || true)
  if [ -z "$val" ]; then
    printf '➖ %-44s not present\n' "$key"
    return 0
  fi
  case ",$want," in
    *",$val,"*)
      printf '✅ %-44s %s\n' "$key" "$val"
      ;;
    *)
      printf '⚠️  %-44s %s (want %s)\n' "$key" "$val" "$want"
      BAD=$((BAD + 1))
      ;;
  esac
}

if [ "$(uname -s)" = Darwin ]; then
  printf '🔎 macOS kernel and network settings\n\n'
  check net.inet.ip.forwarding 0
  check net.inet.icmp.bmcastecho 0
  check net.inet.tcp.blackhole 1,2
  check net.inet.udp.blackhole 1
else
  printf '🔎 Linux kernel and network settings\n\n'
  check kernel.randomize_va_space 2
  check kernel.kptr_restrict 1,2
  check kernel.dmesg_restrict 1
  check kernel.yama.ptrace_scope 1,2,3
  check fs.suid_dumpable 0
  check net.ipv4.conf.all.rp_filter 1
  check net.ipv4.conf.all.accept_redirects 0
  check net.ipv4.conf.all.send_redirects 0
  check net.ipv4.conf.all.accept_source_route 0
  check net.ipv4.conf.all.log_martians 1
  check net.ipv4.tcp_syncookies 1
  check net.ipv4.icmp_echo_ignore_broadcasts 1
  check net.ipv6.conf.all.accept_redirects 0
fi

if [ "$BAD" -eq 0 ]; then
  printf '\n✅ All checked settings match the recommended values.\n'
else
  printf '\n⚠️  %s setting(s) differ. Review them before you change anything.\n' "$BAD"
fi
