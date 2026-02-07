{
  description = "Gurkus der Schlaechter - Godot game development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system: {
        default =
          let
            pkgs = import nixpkgs { inherit system; };
          in
          pkgs.mkShell {
            packages = with pkgs; [
              bash
              git
              github-cli
              go-task

              godot_4
              gdtoolkit_4

              imagemagick
            ];
          };
      });
    };
}
