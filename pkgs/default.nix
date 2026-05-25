{ lib
, ...
}: final: prev: {
  python-basic = prev.python3.withPackages (ps: with ps;
    [ build pip setuptools twine virtualenv ]);

  python-full = prev.python3.withPackages (ps: with ps;
    [ build pip setuptools twine virtualenv tkinter ]);

  #viu = prev.callPackage ./viu.nix { };
  #viu = (prev.viu.override { withSixel = true; }).overrideAttrs (oldAttrs: {
  #  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
  #    final.autoconf
  #    final.automake
  #    final.libtool
  #    final.pkg-config
  #  ];
  #});

  jailed = import ./jailed.nix { inherit lib final prev; };
}
