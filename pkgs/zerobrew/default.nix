# Build zerobrew from source
#
# Zerobrew is a fast macOS package manager written in Rust.
# This derivation builds the `zb` CLI binary from the workspace.

{
  lib,
  rustPlatform,
  zerobrew-src,
  openssl,
  pkg-config,
  stdenv,
  apple-sdk_15,
  darwinMinVersionHook,
}:

rustPlatform.buildRustPackage {
  pname = "zerobrew";
  version = "0.1.0"; # TODO: Extract from Cargo.toml or use source rev

  src = zerobrew-src;

  cargoLock = {
    lockFile = "${zerobrew-src}/Cargo.lock";
    # If there are git dependencies, they may need to be specified here
    # outputHashes = { };
  };

  # Build only the CLI crate
  # cargoBuildFlags = [
  #   "--package"
  #   "zb_cli"
  # ];
  cargoBuildFlags = [ ];
  # cargoTestFlags = [
  #   "--package"
  #   "zb_cli"
  # ];
  cargoTestFlags = [ ];

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    apple-sdk_15
    (darwinMinVersionHook "10.15")
  ];

  # The CLI binary is named 'zb'
  postInstall = ''
    # Ensure the binary is named correctly
    if [ -f "$out/bin/zb_cli" ]; then
      mv "$out/bin/zb_cli" "$out/bin/zb"
    fi
  '';

  meta = with lib; {
    description = "A fast macOS package manager";
    homepage = "https://github.com/lucasgelfond/zerobrew";
    license = licenses.mit; # Check actual license
    maintainers = [ ];
    platforms = platforms.darwin;
    mainProgram = "zb";
  };
}
