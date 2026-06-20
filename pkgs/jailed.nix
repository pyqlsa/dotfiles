# adapted from: https://github.com/andersonjoseph/jailed-agents
{ lib
, final
, prev
, ...
}:
let
  #jail = lib.jail.init final;
  jail = lib.jail.extend {
    pkgs = final;
    additionalCombinators = combinators: {
      banner =
        (import ./combinators/banner.nix {
          inherit combinators lib;
          pkgs = final;
        }).impl;
    };
  };

  # Config files copied directly into the store for bind-mounting into the jail.
  piConfig = import ./pi-config { inherit lib; pkgs = final; };

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
    , bannerMsg ? ""
    , extraPkgs ? [ ]
    , extraTmpfs ? [ ]
    , extraReadwriteDirs ? [ ]
    , extraReadonlyDirs ? [ ]
    , baseJailOptions ? commonJailOptions
    , basePackages ? commonPkgs
    , wrapperCommands ? ""
    , env ? { }
    ,
    }:
    jail name pkg (
      with jail.combinators;
      (
        baseJailOptions
        ++ [ (banner "${bannerMsg}") ]
        ++ [ mount-cwd ]
        # Just in case the jail is launched where `cwd` is (e.g.) "$HOME", we
        # expose the option to shim in extra tmpfs; this can be used to guard
        # specific sub-directories directories of `cwd` from r/w.
        ++ (map (p: tmpfs (noescape p)) (extraTmpfs))
        # Block of command(s) that will execute within a wrapper script, inside
        # the jail before binary.
        ++ [
          (wrap-entry (entry: ''
            ${wrapperCommands}
            exec ${entry}
          ''))
        ]
        # Start adding back r/w dirs, as normal.
        ++ (map (p: readwrite (noescape p)) (extraReadwriteDirs))
        ++ (map (p: readonly (noescape p)) extraReadonlyDirs)
        ++ [ (add-pkg-deps basePackages) ]
        ++ [ (add-pkg-deps extraPkgs) ]
        ++ (prev.lib.mapAttrsToList set-env env)
      )
    );
in
{
  inherit piConfig;

  makeJailedPi =
    { name ? "jailed-pi"
    , pkg ? final.llm-agents.pi
    , bannerMsg ? ""
    , extraPkgs ? [ ]
    , extraReadwriteDirs ? [ ]
    , extraReadonlyDirs ? [ ]
    , sessionDir ? "~/.pi/agent/sessions"
    , baseJailOptions ? commonJailOptions
    , basePackages ? commonPkgs
    , env ? { }
    ,
    }: makeJailedAgent {
      inherit name pkg bannerMsg extraPkgs extraReadonlyDirs baseJailOptions basePackages;
      # Explicit pass-through of pi's session store so we don't lose the
      # ability to resume sessions.
      extraReadwriteDirs = extraReadwriteDirs ++ [ sessionDir ];
      # Just in case the jail is launched where `cwd` == "$HOME", we overlay
      # a tmpfs for pi's base config dir so we don't get any accidental file
      # write leakage from within the jail.
      extraTmpfs = [ "~/.pi/agent" ];
      # Construct links to our configuration and packages within the jail.
      wrapperCommands = ''
        ln -s ${piConfig.settings-json} "$HOME/.pi/agent/settings.json"
        ln -s ${piConfig.models-json} "$HOME/.pi/agent/models.json"
        ln -s ${piConfig.pi-packages} "$HOME/.pi/agent/packages"
      '';
      env = env // {
        PI_CODING_AGENT_DIR = (jail.combinators.noescape "~/.pi/agent");
        PI_CODING_AGENT_SESSION_DIR = (jail.combinators.noescape sessionDir);
      };
    };
}
