{ self, nixpkgs, pkgs }:

with pkgs;

{
  # a hello world example from the top of supermin's website
  welcome = runCommand "supermin-welcome-check" {
    nativeBuildInputs = [
      self.packages.${buildPlatform.system}.supermin
      gnutar
      qemu_test
      # for the appliance
      bash util-linux
    ];
  } ''
    TMPSTORE=$PWD/$(mktemp -d nix-store-XXXXX)
    export HOME=$PWD/$(mktemp -d home-XXXXX)
    mkdir -p $TMPSTORE/nix/store
    mkdir -p ~/.config/nix
    cat > ~/.config/nix/nix.conf <<EOF
    store = $TMPSTORE/nix/store
    EOF
    export NIX_PATH=nixpkgs=${nixpkgs}

    supermin --prepare bash util-linux -o supermin.d -v

    cat > init <<EOF
    #!/bin/sh
    mount -t proc /proc /proc
    mount -t sysfs /sys /sys
    echo Welcome to supermin
    # TODO: Cause qemu exit?
    reboot
    EOF

    chmod +x init
    mkdir supermin.d
    tar zcf supermin.d/init.tar.gz ./init

    supermin --build supermin.d -f ext2 -o appliance.d -v

    qemu-kvm -nodefaults -nographic \
      -kernel appliance.d/kernel \
      -initrd appliance.d/initrd \
      -hda appliance.d/root \
      -serial stdio -append "console=ttyS0 root=/dev/sda"

    touch $out
  '';
}
