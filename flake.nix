{
  description = "YOUR DESCRIPTION HERE";

  inputs = {
    # grab nixpkgs, I use unstable!
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # for 'foreach' system
    utils.url = "github:numtide/flake-utils";

    # grab zig overlay for zig
    zig-flake.url = "github:mitchellh/zig-overlay";

    # put our zig into zls to ensure it matches
    zls-flake = {
      url = "github:zigtools/zls?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.zig-overlay.follows = "zig-flake";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      zig-flake,
      zls-flake,
    }:
    utils.lib.eachSystem
      [
        "x86_64-linux"
      ]
      (
        system:
        let

          # packages for the given system
          pkgs = import nixpkgs {
            inherit system;

            # use overlays
            overlays = [
              (final: prev: {
                zig = zig-flake.packages.${system}."0.16.0";
                zls = zls-flake.packages.${system}.default.overrideAttrs (old: {
                  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.zig ];
                });
              })
            ];
          };
        in
        {
          # on `nix develop`
          devShells.default = pkgs.mkShell {

            buildInputs = [
              pkgs.wayland
              pkgs.sdl3
              pkgs.vulkan-headers
              pkgs.vulkan-loader
              pkgs.vulkan-validation-layers
              pkgs.libxcb
              pkgs.libGL
              pkgs.libxkbcommon
              pkgs.libdecor
              pkgs.libx11
              pkgs.libxcursor
              pkgs.libxrandr
              pkgs.libxi

            ];
            nativeBuildInputs = [
              pkgs.zig
              pkgs.zls
              pkgs.sdl3
              pkgs.wayland
            ];

            VK_LAYER_PATH = "${pkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d";

            LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [
              pkgs.wayland
              pkgs.sdl3
              pkgs.vulkan-headers
              pkgs.vulkan-loader
              pkgs.vulkan-validation-layers
              pkgs.libxcb
              pkgs.libGL
              pkgs.libxkbcommon
              pkgs.libdecor
              pkgs.libx11
              pkgs.libxcursor
              pkgs.libxrandr
              pkgs.libxi

            ]}";
          };
        }
      );
}
