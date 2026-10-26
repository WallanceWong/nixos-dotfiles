#!/usr/bin/env bash
# anon.sh — anonymity toggle for the Kali VM (runs INSIDE Kali, not on NixOS).
#   sudo ./anon.sh on      random MAC + route everything through Tor + UTC clock
#   sudo ./anon.sh off     stop Tor routing, restore the real MAC
#   sudo ./anon.sh status  show Tor routing state and current IP
#
# "Anonymous" hides your IP and location. It does NOT hide you if you log into a
# personal account, and browser fingerprinting still applies — use Tor Browser for web.
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then echo "run with sudo"; exit 1; fi

iface=$(ip route show default 2>/dev/null | awk '/default/{print $5; exit}')
[ -z "${iface:-}" ] && iface=$(ip -o link show | awk -F': ' '$2!="lo"{print $2; exit}')

ensure_deps() {
  if ! command -v kalitorify >/dev/null || ! command -v macchanger >/dev/null || ! command -v tor >/dev/null; then
    echo "[*] installing tor, kalitorify, macchanger ..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq tor kalitorify macchanger
  fi
}

case "${1:-}" in
  on)
    ensure_deps
    echo "[*] clock -> UTC"
    timedatectl set-timezone UTC || true
    echo "[*] randomizing MAC on $iface"
    ip link set "$iface" down
    macchanger -r "$iface" | sed -n 's/^.*New MAC/   New MAC/p'
    ip link set "$iface" up
    sleep 2
    echo "[*] routing all traffic through Tor"
    systemctl start tor@default   # Kali's real daemon; tor.service is only a launcher
    kalitorify -t
    sleep 2
    echo "[*] verifying ..."
    curl -s https://check.torproject.org/api/ip || true
    echo
    echo "[+] anonymous mode ON. Test in browser: https://check.torproject.org"
    ;;
  off)
    kalitorify -c || true
    # kalitorify -c on this build leaves iptables rules, IPv6 off, and a stale
    # DHCP lease — flush and re-lease so the network actually comes back
    iptables -F; iptables -t nat -F; iptables -t mangle -F
    iptables -P INPUT ACCEPT; iptables -P OUTPUT ACCEPT; iptables -P FORWARD ACCEPT
    sysctl -w net.ipv6.conf.all.disable_ipv6=0 >/dev/null
    echo "[*] restoring permanent MAC on $iface"
    ip link set "$iface" down
    macchanger -p "$iface" >/dev/null
    ip link set "$iface" up
    systemctl restart NetworkManager
    sleep 5
    echo "[+] anonymous mode OFF (real network restored)."
    ;;
  status)
    kalitorify -s || true
    echo -n "public IP via curl: "
    curl -s https://check.torproject.org/api/ip || echo "(no response)"
    echo
    ;;
  *)
    echo "usage: sudo $0 {on|off|status}"; exit 1 ;;
esac
