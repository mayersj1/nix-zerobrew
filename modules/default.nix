# Zerobrew installation manager
#
# This module manages the zerobrew installation on macOS via nix-darwin.
# Unlike Homebrew, zerobrew uses a simpler model:
#
# - Fixed prefix: `/opt/zerobrew`
# - Content-addressable store: `/opt/zerobrew/store/{sha256}/`
# - Single architecture (native binary)
# - No tap system
#
# During activation, we create the required directory structure and
# symlink the Nix-built `zb` binary to `/opt/zerobrew/prefix/bin/zb`.

{ pkgs, lib, config, options, ... }:
let
  inherit (lib) types;

  # Marker file to indicate this installation is managed by nix-darwin
  nixMarker = ".managed_by_nix_darwin";

  cfg = config.nix-zerobrew;

  # The zerobrew prefix is always /opt/zerobrew
  zerobrewPrefix = "/opt/zerobrew";

  # Prefix-specific bin/zb launcher
  #
  # Sets up the environment and executes the Nix-built binary.
  # We use `/bin/bash` for compatibility.
  zbLauncher = pkgs.writeScriptBin "zb" (''
    #!/bin/bash
    set -euo pipefail
    export ZEROBREW_PREFIX="${zerobrewPrefix}"
    export NIX_ZB_BIN="${cfg.package}/bin/zb"
    export PATH="${zerobrewPrefix}/prefix/bin:$PATH"
  '' + (lib.optionalString (cfg.extraEnv != {})
        (lib.concatLines (lib.mapAttrsToList (name: value: "export ${name}=${lib.escapeShellArg value}") cfg.extraEnv)))
     + (builtins.readFile ./zb.tail.sh));

  setupZerobrew = pkgs.writeShellScript "setup-zerobrew" ''
    set -euo pipefail
    source ${./utils.sh}

    NIX_ZEROBREW_UID=$(id -u "${cfg.user}" || (error "Failed to get UID of ${cfg.user}"; exit 1))
    NIX_ZEROBREW_GID=$(dscl . -read "/Groups/${cfg.group}" | awk '($1 == "PrimaryGroupID:") { print $2 }' || (error "Failed to get GID of ${cfg.group}"; exit 1))

    ZEROBREW_PREFIX="${zerobrewPrefix}"

    is_in_nix_store() {
      [[ "$1" != "${builtins.storeDir}"* ]] || return 0

      if [[ -e "$1" ]]
      then
        path="$(readlink -f $1)"
      else
        path="$1"
      fi

      if [[ "$path" == "${builtins.storeDir}"* ]]
      then
        return 0
      else
        return 1
      fi
    }

    is_occupied() {
      [[ -e "$1" ]] && ([[ ! -L "$1" ]] || ! is_in_nix_store "$1")
    }

    >&2 echo "setting up Zerobrew ($ZEROBREW_PREFIX)..."

    # Check for existing non-managed installation
    if [[ -e "$ZEROBREW_PREFIX" ]] && [[ ! -e "$ZEROBREW_PREFIX/${nixMarker}" ]]; then
      if [[ -z "${toString cfg.autoMigrate}" ]]; then
        warn "An existing Zerobrew installation exists at $ZEROBREW_PREFIX"
        ohai "Set nix-zerobrew.autoMigrate = true; to allow nix-zerobrew to migrate the installation"
        ohai "During auto-migration, nix-zerobrew will take ownership of the existing installation"
        exit 1
      fi

      ohai "Taking ownership of existing Zerobrew installation..."
    fi

    # Initialize the prefix directory structure
    if [[ ! -e "$ZEROBREW_PREFIX/${nixMarker}" ]]; then
      initialize_zerobrew_prefix
    fi

    # Link the Nix-built zb binary
    BIN_ZB="$ZEROBREW_PREFIX/prefix/bin/zb"
    if is_occupied "$BIN_ZB"; then
      error "An existing $BIN_ZB is in the way"
      exit 1
    fi
    /bin/ln -shf "${zbLauncher}/bin/zb" "$BIN_ZB"
  '';

in {
  options = {
    nix-zerobrew = {
      enable = lib.mkOption {
        description = ''
          Whether to install and manage Zerobrew.
        '';
        type = types.bool;
        default = false;
      };

      package = lib.mkOption {
        description = ''
          The zerobrew package to use.
        '';
        type = types.package;
      };

      autoMigrate = lib.mkOption {
        description = ''
          Whether to allow nix-zerobrew to automatically migrate existing Zerobrew installations.

          When enabled, the activation script will take ownership of
          existing installations while keeping installed packages.
        '';
        type = types.bool;
        default = false;
      };

      user = lib.mkOption {
        description = ''
          The user owning the Zerobrew directories.
        '';
        type = types.str;
      };

      group = lib.mkOption {
        description = ''
          The group owning the Zerobrew directories.
        '';
        type = types.str;
        default = "admin";
      };

      extraEnv = lib.mkOption {
        description = ''
          Extra environment variables to set for Zerobrew.
        '';
        type = types.attrsOf types.str;
        default = {};
        example = lib.literalExpression ''
          {
            ZEROBREW_NO_ANALYTICS = "1";
          }
        '';
      };

      # Shell integrations
      enableBashIntegration = lib.mkEnableOption "zerobrew bash integration" // {
        default = true;
      };

      enableFishIntegration = lib.mkEnableOption "zerobrew fish integration" // {
        default = true;
      };

      enableZshIntegration = lib.mkEnableOption "zerobrew zsh integration" // {
        default = true;
      };
    };
  };

  config = lib.mkIf (cfg.enable) {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "nix-zerobrew is only supported on macOS";
      }
      {
        # nix-darwin has migrated away from user activation
        assertion = options.system ? primaryUser;
        message = "Please update your nix-darwin version to use system-wide activation";
      }
    ];

    # Shell integrations - add zerobrew prefix bin to PATH
    programs.bash.interactiveShellInit = lib.mkIf cfg.enableBashIntegration ''
      if [ -d "${zerobrewPrefix}/prefix/bin" ]; then
        export PATH="${zerobrewPrefix}/prefix/bin:$PATH"
      fi
    '';

    programs.zsh.interactiveShellInit = lib.mkIf cfg.enableZshIntegration ''
      if [ -d "${zerobrewPrefix}/prefix/bin" ]; then
        export PATH="${zerobrewPrefix}/prefix/bin:$PATH"
      fi
    '';

    programs.fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
      if test -d "${zerobrewPrefix}/prefix/bin"
        fish_add_path "${zerobrewPrefix}/prefix/bin"
      end
    '';

    environment.systemPackages = [ zbLauncher ];

    system.activationScripts = {
      setup-zerobrew.text = ''
        >&2 echo "setting up Zerobrew prefix..."
        ${setupZerobrew}
      '';
    };
  };
}
