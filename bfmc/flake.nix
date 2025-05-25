{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
  };

  outputs = { self, nix-ros-overlay, nixpkgs }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            nix-ros-overlay.overlays.default
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "ROS";

          NIX_CFLAGS_COMPILE = pkgs.lib.concatStringsSep " " [
            "-Wno-error=implicit-function-declaration"
            "-Wno-error=incompatible-pointer-types"
            "-Wno-error=int-conversion"
          ];
          NIX_CXXFLAGS_COMPILE = pkgs.lib.concatStringsSep " " [
            "-Wno-error=implicit-function-declaration"
            "-Wno-error=incompatible-pointer-types"
            "-Wno-error=int-conversion"
          ];

          packages = [
            (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
              requests opencv4 psutil python-lsp-server setuptools distutils pyqt5 pyglm numpy pyyaml pandas pyopengl pyopengl-accelerate cryptography twisted pillow scipy networkx matplotlib freetype-py
            ]))
            (with pkgs.rosPackages.noetic; buildEnv {
              paths = [
                ackermann-msgs
                urdf
                camera-info-manager
                ros-core
                rospy
                roscpp
                cv-bridge
                tf2
                tf
                image-transport
                geometry-msgs
                tf2-geometry-msgs
                gazebo-msgs
                gazebo-ros
                robot-localization
              ];
            })
          ];
        };
      });

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
