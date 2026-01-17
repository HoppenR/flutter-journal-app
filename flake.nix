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
            buildInputs = [
              pkgs.flutter338
              pkgs.git
              pkgs.unzip
              (pkgs.writeShellScriptBin "build-web" ''
                exec flutter build web --base-href /journal/ --wasm --release "$@"
              '')

              pkgs.jdk17 # For Android
            ];

            shellHook = ''
              function cleanup() {
                echo "󰃢 Cleaning up Flutter/Dart artifacts..."
                set -x
                if [[ -d "$HOME/.dart-tool" ]]; then
                  rm --recursive --interactive=once "$HOME/.dart-tool"
                fi
                if [[ -d "$HOME/.pub-cache" ]]; then 
                  rm --recursive --interactive=once "$HOME/.pub-cache"
                fi
                if [[ -f "$HOME/.flutter" ]]; then
                  rm --interactive "$HOME/.flutter"
                fi
              }
              trap cleanup EXIT

              echo "Using Flutter from: ${pkgs.flutter338}"
              flutter --version
            '';
          };
        }
      );
    };
}
