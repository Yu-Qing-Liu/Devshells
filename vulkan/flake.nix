{
  inputs = {
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = { self, nixpkgs-unstable }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs-unstable {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "VULKAN";

          shellHook = ''
            export SHELL=/run/current-system/sw/bin/zsh
          '';

          packages = [
            # C++ Tools
            pkgs.stdenv.cc
            pkgs.cmake
            pkgs.gnumake
            pkgs.clang-tools
            pkgs.llvmPackages.openmp
            pkgs.gdb
            pkgs.valgrind
            # Graphics drivers
            pkgs.mesa
            pkgs.libglvnd
            pkgs.linuxPackages.nvidia_x11
            # Vulkan
            pkgs.vulkan-loader
            pkgs.vulkan-validation-layers
            pkgs.vulkan-tools
            pkgs.spirv-tools
            pkgs.shaderc
            # Dependencies
            pkgs.glfw
            pkgs.glm
            pkgs.freetype
          ];

          GDK_BACKEND = "x11";
          QT_QPA_PLATFORM = "xcb";
          PYOPENGL_PLATFORM="x11";
          SDL_VIDEODRIVER = "x11";
        };
      });
}
