{
  description = "Flutter environment for flutter-journal-app";
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShellNoCC {
          name = "flutter338-devshell";
          buildInputs = with pkgs; [
            flutter338
            git
            unzip
            jdk17 # For Android

            (writeShellScriptBin "build-web" ''
              exec flutter build web --base-href /journal/ --wasm --release "$@"
            '')
          ];

          NIX_DART_BIN = "${pkgs.flutter338}/bin/dart";

          shellHook = /* bash */ ''
            export JOURNAL_HOME=$(git rev-parse --show-toplevel) || exit
            export XDG_CONFIG_DIRS="$JOURNAL_HOME/.nvim_config:$XDG_CONFIG_DIRS"
          '';
        };
      }
    ));
}
