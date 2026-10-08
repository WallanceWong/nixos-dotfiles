# Development shells:
#   nix develop ~/nixos-dotfiles#kernel   — build and test the Linux kernel
#   nix develop ~/nixos-dotfiles#osdev    — write your own OS (bare-metal cross compilers)
# Or in a project: echo "use flake ~/nixos-dotfiles#kernel" > .envrc && direnv allow
pkgs:
let
  llvm = pkgs.llvmPackages;
  cross = t: pkgs.pkgsCross.${t}.buildPackages;
  virtme-ng = pkgs.callPackage ./pkgs/virtme-ng.nix { };
in
{
  # ── Linux kernel ─────────────────────────────────────────────────
  # Everything nixpkgs itself uses to build the kernel, plus clang/LLVM
  # (make LLVM=1), Rust-for-Linux, and tools to boot and debug the result.
  kernel = pkgs.mkShell {
    name = "kernel";
    inputsFrom = [ pkgs.linux_latest ];
    packages = with pkgs; [
      # build
      gnumake bc flex bison perl python3 openssl elfutils zstd lz4 xz cpio rsync kmod
      pahole                       # BTF (CONFIG_DEBUG_INFO_BTF)
      ncurses pkg-config           # make menuconfig
      ccache bear                  # faster rebuilds, compile_commands.json
      llvm.clang llvm.lld llvm.llvm
      # Rust-for-Linux (make LLVM=1 rustavailable)
      rustc cargo rustfmt clippy rust-bindgen
      # test and debug
      qemu gdb virtme-ng           # vng brings the busybox binary it needs
      sparse coccinelle
      b4                           # fetch and send patch series from lore.kernel.org
    ];
    RUST_LIB_SRC = "${pkgs.rustPlatform.rustLibSrc}";
    hardeningDisable = [ "all" ];  # the kernel sets its own flags
    shellHook = ''
      export KBUILD_BUILD_HOST=nixos CCACHE_DIR=''${CCACHE_DIR:-$HOME/.cache/ccache}
      echo "kernel shell — make -j$(nproc) [LLVM=1]; vng --build / vng to boot it in QEMU"
    '';
  };

  # ── your own OS ──────────────────────────────────────────────────
  # Bare-metal (freestanding) cross compilers for x86_64, i686, RISC-V and ARM64,
  # clang/lld (cross by default: --target=x86_64-elf), assemblers, bootloaders,
  # UEFI firmware for QEMU and image tools.
  osdev = pkgs.mkShell {
    name = "osdev";
    packages = with pkgs; [
      (cross "x86_64-embedded").gcc     # x86_64-elf-gcc, -ld, -objdump …
      (cross "i686-embedded").gcc       # i686-elf-gcc
      (cross "riscv64-embedded").gcc    # riscv64-none-elf-gcc
      (cross "aarch64-embedded").gcc    # aarch64-none-elf-gcc
      llvm.clang-unwrapped llvm.lld llvm.llvm
      nasm gnumake cmake ninja meson
      qemu gdb
      limine grub2 xorriso mtools dosfstools parted
      OVMF.fd                           # UEFI firmware: qemu -bios $OVMF
    ];
    OVMF = "${pkgs.OVMF.fd}/FV/OVMF.fd";
    hardeningDisable = [ "all" ];       # freestanding code: no stack protector, no PIE
    shellHook = ''
      echo "osdev shell — x86_64-elf-gcc, i686-elf-gcc, riscv64-none-elf-gcc, aarch64-none-elf-gcc, clang --target=…, qemu-system-*, \$OVMF"
    '';
  };
}
