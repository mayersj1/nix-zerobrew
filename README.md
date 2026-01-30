# nix-zerobrew

Declarative [Zerobrew](https://github.com/lucasgelfond/zerobrew) installation manager for [nix-darwin](https://github.com/LnL7/nix-darwin).

## Overview

nix-zerobrew provides a nix-darwin module for managing Zerobrew installations on macOS. Zerobrew is a fast, modern macOS package manager written in Rust that provides 5-20x faster installation speeds compared to Homebrew.

### Key Features

- **Declarative Configuration**: Manage your Zerobrew installation through Nix
- **Nix-built Binary**: Zerobrew is compiled from source via Nix
- **Shell Integration**: Automatic PATH configuration for bash, zsh, and fish
- **Migration Support**: Can migrate existing Zerobrew installations

## Installation

Add nix-zerobrew to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-zerobrew.url = "github:yourusername/nix-zerobrew";
    nix-zerobrew.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, nix-zerobrew, ... }: {
    darwinConfigurations.myhost = nix-darwin.lib.darwinSystem {
      modules = [
        nix-zerobrew.darwinModules.default
        {
          nix-zerobrew = {
            enable = true;
            user = "yourusername";
          };
        }
      ];
    };
  };
}
```

## Configuration Options

### Basic Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Whether to enable Zerobrew management |
| `user` | string | required | User owning Zerobrew directories |
| `group` | string | `"admin"` | Group owning Zerobrew directories |
| `autoMigrate` | bool | `false` | Allow migration of existing installations |

### Environment

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `extraEnv` | attrs | `{}` | Extra environment variables for Zerobrew |

### Shell Integration

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enableBashIntegration` | bool | `true` | Add Zerobrew to bash PATH |
| `enableZshIntegration` | bool | `true` | Add Zerobrew to zsh PATH |
| `enableFishIntegration` | bool | `true` | Add Zerobrew to fish PATH |

## Example Configuration

```nix
{
  nix-zerobrew = {
    enable = true;
    user = "alice";
    group = "admin";
    autoMigrate = true;

    extraEnv = {
      ZEROBREW_NO_ANALYTICS = "1";
    };

    # Shell integrations (all enabled by default)
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableFishIntegration = true;
  };
}
```

## Directory Structure

nix-zerobrew creates the following directory structure:

```
/opt/zerobrew/
  store/           # Content-addressable package store (SHA256)
  db/              # SQLite database for package metadata
  cache/           # Download cache
  locks/           # Lock files for concurrent operations
  prefix/          # User-facing installation
    bin/           # Executables (including zb)
    Cellar/        # Installed packages
    opt/           # Version-independent links
    lib/           # Shared libraries
    include/       # Header files
    share/         # Shared data
    etc/           # Configuration files
```

## Usage

After activation, use the `zb` command:

```bash
# Install a package
zb install jq

# Search for packages
zb search ripgrep

# List installed packages
zb list

# Uninstall a package
zb uninstall jq
```

## Differences from nix-homebrew

| Aspect | nix-homebrew | nix-zerobrew |
|--------|--------------|--------------|
| Package Manager | Homebrew (Ruby) | Zerobrew (Rust) |
| Prefix | `/opt/homebrew` (ARM) or `/usr/local` (Intel) | `/opt/zerobrew` (fixed) |
| Taps | Complex tap management | No taps needed |
| Rosetta | Separate prefixes for ARM/Intel | Single prefix |
| CLI | `brew` | `zb` |
| Build | Ruby scripts | Compiled Rust binary |

## Building from Source

To build the zerobrew package directly:

```bash
nix build .#zerobrew
./result/bin/zb --help
```

## License

MIT License - See LICENSE file for details.

## Acknowledgments

- [Zerobrew](https://github.com/lucasgelfond/zerobrew) by Lucas Gelfond
- [nix-homebrew](https://github.com/zhaofengli/nix-homebrew) for inspiration and patterns
