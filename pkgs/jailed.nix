# adapted from: https://github.com/andersonjoseph/jailed-agents
{ lib
, final
, prev
, ...
}:
let
  jail = lib.jail.init final;

  commonPkgs = with final; [
    bashInteractive
    curl
    wget
    jq
    git
    which
    ripgrep
    gnugrep
    gawkInteractive
    ps
    findutils
    gzip
    unzip
    gnutar
    diffutils
    gnused
  ];

  commonJailOptions = with jail.combinators;  [
    network
    time-zone
    no-new-session
  ];

  makeJailedAgent =
    { name
    , pkg
    , configPaths
    , extraPkgs ? [ ]
    , extraReadwriteDirs ? [ ]
    , extraReadonlyDirs ? [ ]
    , extraLinkedPaths ? [ ]
    , env ? { }
    , baseJailOptions ? commonJailOptions
    , basePackages ? commonPkgs
    ,
    }:
    jail name pkg (
      with jail.combinators;
      (
        baseJailOptions
        ++ (map (p: readwrite (noescape p)) (configPaths ++ extraReadwriteDirs))
        ++ (map (p: readonly (noescape p)) extraReadonlyDirs)
        # this might only work if the symlinks you're wanting to establish in the
        # jail aren't otherwise already in some directory being mounted into the
        # jail; if they are, there will be a collision and bwrap will fail on launch
        ++ (map (p: runtime-deep-ro-bind (noescape p)) extraLinkedPaths)
        ++ [ mount-cwd ]
        ++ [ (add-pkg-deps basePackages) ]
        ++ [ (add-pkg-deps extraPkgs) ]
        ++ (prev.lib.mapAttrsToList set-env env)
      )
    );
in
{
  makeJailedPi =
    { name ? "jailed-pi"
    , pkg ? final.llm-agents.pi
    , extraPkgs ? [ ]
    , extraReadwriteDirs ? [ ]
    , extraReadonlyDirs ? [ ]
    , extraLinkedPaths ? [ ]
    , env ? { }
    , baseJailOptions ? commonJailOptions
    , basePackages ? commonPkgs
    ,
    }:
    makeJailedAgent {
      inherit
        name
        pkg
        extraPkgs
        extraReadwriteDirs
        extraReadonlyDirs
        extraLinkedPaths
        baseJailOptions
        basePackages
        env
        ;
      configPaths = [
        "~/.pi"
      ];
    };
}
