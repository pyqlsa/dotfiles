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
      # Opt-in access to the host Nix daemon so the agent can run builds and dev
      # shells. When true this:
      #   * ro-binds all of /nix — MUST stay `defer`red so it lands after jail.nix's
      #     base per-path runtime-closure binds and shadows them with one mount
      #     (upstream jailed-agents commit 034b0a9 fixed a real bug this way);
      #   * rw-binds /nix/var/nix/daemon-socket — Nix >=2.8 listens at .../socket inside
      #     this root-owned 0755 dir; no env vars needed: non-root clients resolve the
      #     store URI "auto" to exactly that path;
      #   * ro-binds /etc/nix/nix.conf — host-parity config (flake experimental
      #     features, substituters) with no writable nix config anywhere in the jail;
      #   * adds `nix` to PATH.
      # Upstream's warning applies verbatim: this lets the agent build and run arbitrary
      # nixpkgs packages via the daemon. It does NOT grant root, config write access, or any
      # way to apply a system rebuild from inside.
    , enableNix ? false
      # Read-only mount of a NixOS/system config dir so the agent can read what is
      # actually active on this host. String only — writable variants are deliberately
      # not supported. null disables. only useful if enableNix == true;
    , nixConfigDir ? "/etc/nixos"
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
        ++ (map
          (p: add-runtime ''
            if [ ! -d ${p} ]; then
              mkdir -p ${p}
            fi
          '')
          (extraReadwriteDirs))
        ++ (map (p: readwrite (noescape p)) (extraReadwriteDirs))
        ++ (map (p: readonly (noescape p)) extraReadonlyDirs)
        ++ [ (add-pkg-deps basePackages) ]
        # nix CLI joins the extra packages only when daemon access is opted in.
        ++ [ (add-pkg-deps (extraPkgs ++ lib.optionals enableNix [ final.nix ])) ]
        ++ (prev.lib.mapAttrsToList set-env env)
        # --- opt-in Nix daemon access; see param docs above and plans/jailed-pi-nix-access/ ---
        ++ (lib.optionals enableNix [
          (defer (ro-bind "/nix" "/nix"))
          (readwrite "/nix/var/nix/daemon-socket")
          (readonly "/etc/nix/nix.conf")
        ])
        # --- read-only system config dir, only if enableNix ---
        ++ (lib.optional (enableNix && (nixConfigDir != null)) (readonly (noescape nixConfigDir)))
      )
    );
in
rec
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
    , enableNix ? false
    , nixConfigDir ? "/etc/nixos"
    , env ? { }
    ,
    }: makeJailedAgent {
      inherit name pkg bannerMsg extraPkgs extraReadonlyDirs baseJailOptions basePackages;
      inherit enableNix nixConfigDir;
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
  pi = (makeJailedPi {
    name = "pi";
    enableNix = true;
    nixConfigDir = null; # we run from a git-controlled flake, not `configuration.nix`
    extraPkgs = with final;[
      python-basic
      bun
    ];
  });
}
