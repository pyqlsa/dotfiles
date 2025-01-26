# dotfiles
System configs, 'dotfiles', and... stuff.

## install notes

### partitioning and config generation

#### no disko

For the average system, booted into a minimal disk image...
`./scripts/partition.sh` for an opinionated, minimally guided, partioning scheme.
```bash
./scripts/partition.sh -d <device> -e

nixos-generate-config --root /mnt
```

#### disko

For the average system, booted into a minimal disk image, when a disko config is defined.
```bash
nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode disko ./hosts/<host>/disko.nix

nixos-generate-config --no-filesystems --root /mnt
```

For raspberry pi, track this: https://github.com/nix-community/disko/issues/550

### OS installation

```bash
# after configs are generated, reconcile /mnt/etc/nixos/*.nix with config in ./hosts/<host>;
# from here, we'll abondon the generated configs in /mnt/etc/nixos/*.nix in favor of our flake.
nixos-install --root /mnt --flake .#<host>

# be careful not to lose any potential diffs; either commit and push them, or copy them into a safe
# location on the newly built system still attached to /mnt.
```

## references

When initially building this out, some of the below were helpful and inspiring along the way:
- https://chrishayward.xyz/dotfiles/
- https://gvolpe.com/blog/nix-flakes/
- https://sr.ht/~misterio/nix-config/
- https://github.com/jordanisaacs/dotfiles
- https://github.com/jordanisaacs/neovim-flake
- https://github.com/wiltaylor/dotfiles
- https://github.com/wiltaylor/neovim-flake

### raspberry pi
- https://nix.dev/tutorials/nixos/installing-nixos-on-a-raspberry-pi.html
