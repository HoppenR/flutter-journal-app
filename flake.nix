{
  description = "Flutter environment for flutter-journal-app";
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
  };
  outputs = { nixpkgs, systems, ... }:
  let
    eachSystem = nixpkgs.lib.genAttrs (import systems);
  in
  {
    devShells = eachSystem (system:
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
            pkgs.jdk17 # For Android
          ];

          shellHook = ''
            export FLUTTER_HOME="${pkgs.flutter338}"
            export PATH="$FLUTTER_HOME/bin:$PATH"
            echo "Using Flutter from: $FLUTTER_HOME"
            flutter --version
          '';
        };
      }
    );
  };
}
