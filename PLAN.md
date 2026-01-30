# nix-zerobrew - Testing and Verification Plan

## Project Status

All files have been created. The project needs to be initialized as a git repo and tested.

## Files Created

```
nix-zerobrew/
├── flake.nix                    # Main flake with zerobrew-src input
├── modules/
│   ├── default.nix              # Core nix-darwin module (~210 lines)
│   ├── utils.sh                 # Shell utilities for directory setup
│   └── zb.tail.sh               # Launcher script tail
├── pkgs/
│   ├── default.nix              # Package exports
│   └── zerobrew/
│       └── default.nix          # Rust build derivation
└── README.md                    # Documentation
```

## Tasks to Complete

### 1. Initialize Git Repository
```bash
git init
git add .
```

### 2. Test Flake Evaluation
```bash
nix flake check
```

### 3. Build the Zerobrew Package
```bash
nix build .#zerobrew
./result/bin/zb --help
```

### 4. Fix Any Build Issues

The Rust build may need adjustments:
- `cargoHash` might be needed instead of `cargoLock.lockFile`
- Additional darwin frameworks might be required
- The binary name output might need verification

### 5. Test Module Evaluation

Create a test configuration to verify the module loads:
```bash
nix eval .#darwinModules.default --apply 'x: "ok"'
```

## Potential Issues to Watch For

1. **Cargo.lock handling**: The `cargoLock.lockFile` approach may need `cargoHash` instead
2. **Binary name**: Verify if the output is `zb` or `zb_cli`
3. **Darwin frameworks**: May need additional frameworks like `CoreFoundation`
4. **Git dependencies**: If zerobrew has git dependencies in Cargo.lock, they need `outputHashes`

## Quick Fixes Reference

### If cargoHash is needed instead of cargoLock:
```nix
# In pkgs/zerobrew/default.nix, replace cargoLock with:
cargoHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
# Then run nix build and use the hash from the error message
```

### If additional frameworks needed:
```nix
buildInputs = [
  openssl
] ++ lib.optionals stdenv.isDarwin [
  darwin.apple_sdk.frameworks.Security
  darwin.apple_sdk.frameworks.SystemConfiguration
  darwin.apple_sdk.frameworks.CoreFoundation
  darwin.apple_sdk.frameworks.CoreServices
];
```

## Success Criteria

1. `nix flake check` passes
2. `nix build .#zerobrew` produces a working binary
3. `./result/bin/zb --help` shows usage information
4. Module can be imported in a nix-darwin configuration
