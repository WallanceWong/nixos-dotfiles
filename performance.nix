# Speed and smoothness for this ThinkPad (Core Ultra 5 225H: 4 performance +
# 10 efficient cores, 16 GB). Measured before/after with a small benchmark;
# see README "Performance".
{ config, pkgs, lib, ... }:
{
  # CPU scheduler: the kernel's own (EEVDF). Tested against sched_ext
  # schedulers (lavd, bpfland, flash, cosmos) under full load on this laptop:
  # none beat it overall — it had by far the best typical wake-up latency and
  # near-top throughput — so nothing is added here.

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

  # when memory runs out, systemd-oomd stops the one app that is thrashing (apps
  # run in their own scopes) instead of the whole laptop freezing for minutes
  systemd.oomd = {
    enable = true;
    enableUserSlices = true;
  };

  # don't write a timestamp every time a file is read
  fileSystems."/".options = [ "noatime" ];
}
