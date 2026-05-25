# https://notashelf.dev/posts/extended-nixpkgs-lib
# https://github.com/NotAShelf/nvf/blob/main/lib/stdlib-extended.nix
{ inputs
, ...
} @ args:
inputs.nixpkgs.lib.extend (self: super: {
  # New functions should not be added here, but to files imported
  # by `./default.nix` under their own categories.

  # Make our custom functions available under `lib.sys` where stdlib-extended.nix
  # is imported with the appropriate arguments. For end-users, a `lib` output
  # will be accessible from the flake. (E.g.) for an input called `dots`,
  # `inputs.dots.lib.sys` will return the set below.
  sys = import ./. {
    inherit (args) inputs self;
    lib = self;
  };

  # not claiming other upstream libs as our own, just passing through;
  # for an input `dots`, exposed as `inputs.dots.lib.jail`
  jail = inputs.jail-nix.lib;
})
