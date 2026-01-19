{
  description = "Flutter environment for flutter-journal-app";
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs =
    { nixpkgs, systems, ... }:
    let
      eachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      devShells = eachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
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

            shellHook = /* bash */ ''
              function cleanup() {
                echo "󰃢 Cleaning up Flutter/Dart artifacts..."
                set -x
                if [[ -d "$HOME/.dart-tool" ]]; then
                  rm --recursive --interactive=once "$HOME/.dart-tool"
                fi
                if [[ -f "$HOME/.flutter" ]]; then
                  rm --interactive "$HOME/.flutter"
                fi
              }
              trap cleanup EXIT

              export JOURNAL_HOME=$(git rev-parse --show-toplevel) || exit
              export NIX_DART_BIN="${pkgs.flutter338}/bin/dart"
              export PUB_CACHE="$JOURNAL_HOME/.pub-cache"
              export XDG_CONFIG_DIRS="$JOURNAL_HOME/.nvim_config:$XDG_CONFIG_DIRS"
              export ANALYZER_STATE_LOCATION_OVERRIDE="$HOME/.cache/nvim/dartServer"

              echo "Using Flutter from: ${pkgs.flutter338}"
              echo "Added neovim config: $JOURNAL_HOME/.nvim_config"
              echo "Run 'flutter pub get' if this is your first time."
              ${pkgs.flutter338}/bin/flutter --version

              command zsh
              exit
            '';
          };
        }
      );
    };
}
