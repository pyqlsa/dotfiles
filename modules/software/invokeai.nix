{ pkgs
, config
, lib
, ...
}:
with pkgs;
with lib; let
  cfg = config.sys.invokeai;
in
{
  # requires `inputs.nixified-ai-flake.nixosModules.invokeai-amd`
  options.sys.invokeai = {
    enable = mkEnableOption (lib.mdDoc "invokeai services");

    trustCache = mkOption {
      type = types.bool;
      description = "trust the nixified-ai flake binary cache";
      default = true;
    };
  };

  config = lib.mkIf (cfg.enable) {
    services.invokeai.enable = true;
    sys.software = with pkgs; [
      invokeai-amd
    ];

    # https://github.com/nixified-ai/flake
    nix = lib.mkIf (cfg.trustCache && config.sys.nix.enable) {
      settings = {
        trusted-substituters = [
          "https://ai.cachix.org"
        ];
        trusted-public-keys = [
          "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
        ];
        extra-substituters = [
          "https://ai.cachix.org"
        ];
        extra-trusted-public-keys = [
          "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
        ];
      };
    };
  };
}
