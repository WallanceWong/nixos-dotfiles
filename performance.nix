# Speed and smoothness for this ThinkPad (Core Ultra 5 225H: 4 performance +
# 10 efficient cores, 16 GB). Measured before/after with a small benchmark;
# see README "Performance".
{ config, pkgs, lib, ... }:
{
  # CPU scheduler: the kernel's own (EEVDF). Tested against sched_ext
  # schedulers (lavd, bpfland, flash, cosmos) under full load on this laptop:
  # none beat it overall — it had by far the best typical wake-up latency and
  # near-top throughput — so nothing is added here.

  # Boost: left to the firmware. Capping the 4 fast cores during all-core load
  # gave +17% in a pure-compute benchmark, but nothing in real work (xz,
  # compiling: within noise) — those are limited by memory bandwidth (one RAM
  # stick, single channel), not heat. A second stick is the real upgrade.

  # Wi-Fi power saving off while on the charger: measured here, the router
  # round trip goes from 7.2 ms (jitter 3.8 ms) to 2.2 ms (jitter 0.3 ms).
  # On battery it stays on. Re-applied on plug/unplug and on every reconnect.
  systemd.services.wifi-powersave = let
    script = pkgs.writeShellScript "wifi-powersave" ''
      ac=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 0)
      mode=on; [ "$ac" = 1 ] && mode=off
      for w in /sys/class/net/*/wireless; do
        [ -e "$w" ] || continue
        ${pkgs.iw}/bin/iw dev "$(basename "$(dirname "$w")")" set power_save $mode
      done
    '';
  in {
    description = "Wi-Fi power saving only on battery";
    after = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = { Type = "oneshot"; ExecStart = script; };
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", KERNEL=="AC", ACTION=="change", RUN+="${pkgs.systemd}/bin/systemctl start --no-block wifi-powersave.service"
  '';
  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeText "wifi-powersave-hook" ''
      [ "$2" = up ] && ${pkgs.systemd}/bin/systemctl start --no-block wifi-powersave.service
      exit 0
    '';
  }];

  # (no thermald: on ThinkPads with Lenovo's DYTC thermal control the firmware
  # manages heat itself, and thermald refuses to run)

  # compressed RAM swap (zram) may hold up to all of RAM, and the kernel is
  # told swapping to it is cheap — more apps stay alive before anything slows
  zramSwap.memoryPercent = 100;
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;               # no swap read-ahead: zram is random access
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    # BBR: faster, steadier transfers over Wi-Fi
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
  };
  boot.kernelModules = [ "tcp_bbr" ];

  # when memory (and the zram swap) truly runs out, earlyoom ends the single
  # biggest process — a browser tab first — instead of the laptop freezing.
  # Never the compositor, the shell, the terminal or audio. (Not systemd-oomd:
  # it kills whole cgroups, and keybind-launched apps share Hyprland's.)
  services.earlyoom = {
    enable = true;
    freeMemThreshold = 4;
    freeSwapThreshold = 8;
    enableNotifications = true;
    extraArgs = [
      "--prefer" "^(Isolated Web Co|Web Content|electron|code|pictoblox)$"
      "--avoid" "^(\\.?Hyprland.*|\\.?quickshell.*|\\.?kitty.*|pipewire.*|wireplumber|systemd.*|sshd|bash)$"
    ];
  };

  # don't write a timestamp every time a file is read
  fileSystems."/".options = [ "noatime" ];
}
