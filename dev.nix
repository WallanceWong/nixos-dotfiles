# OS and kernel development — the system-wide part. The toolchains live in the
# flake's dev shells (`nix develop ~/nixos-dotfiles#kernel` / `#osdev`); everyday
# tools (QEMU, GDB, clangd, …) are in home.nix. See README "OS and kernel development".
{ config, pkgs, ... }:
{
  # man pages for syscalls, the C library and POSIX (man 2 mmap, man 3p pthread_create)
  documentation.dev.enable = true;
  documentation.man.cache.enable = false;   # its generation slows every rebuild

  environment.systemPackages = [
    pkgs.man-pages
    pkgs.man-pages-posix
    config.boot.kernelPackages.perf   # matches the running kernel
    pkgs.bpftrace
    pkgs.trace-cmd
  ];

  # perf without sudo for your own processes (default 2 also hides kernel profiles)
  boot.kernel.sysctl."kernel.perf_event_paranoid" = 1;

  # QEMU/KVM: /dev/kvm is already open to everyone here; the group is for tools
  # that check it
  users.users.Wallance.extraGroups = [ "kvm" ];

  # enter a project's dev shell automatically when you cd into it (.envrc)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # everyday tools, always on PATH
  users.users.Wallance.packages = with pkgs; [
    gcc gnumake                       # quick one-off builds (project shells bring their own)
    gdb                               # all targets: x86, ARM, RISC-V; QEMU's gdbstub
    qemu                              # every architecture, with KVM on x86
    (callPackage ./pkgs/virtme-ng.nix { })   # `vng`: boot a freshly built kernel in seconds
    clang-tools                       # clangd (editor), clang-format, clang-tidy
    bear ccache
    cscope universal-ctags
    nasm
    strace ltrace
    xorriso mtools dosfstools         # bootable ISOs / FAT images for your OS
    file xxd hexyl
  ];

  home-manager.users.Wallance = {
    # GDB: history, readable output, and allow the kernel's vmlinux-gdb.py helpers
    # from anything under ~/src
    xdg.configFile."gdb/gdbinit".text = ''
      set history save on
      set history size 10000
      set history filename ~/.local/state/gdb_history
      set print pretty on
      set confirm off
      add-auto-load-safe-path ~/src
    '';
    # kernel rebuilds mostly reuse objects
    xdg.configFile."ccache/ccache.conf".text = ''
      max_size = 25G
      compression = true
    '';
  };
}
