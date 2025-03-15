{
  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs";
  };

  outputs = { self, nix-ros-overlay, nixpkgs}:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        cudaOverlay = final: prev: {
          cudaPackages = prev.cudaPackages_11 // {
            tensorrt = prev.cudaPackages_11.tensorrt_8_6.overrideAttrs (oldAttrs: {
              dontCheckForBrokenSymlinks = true;
              outputs = [ "out" ];
              fixupPhase = ''
                ${oldAttrs.fixupPhase or ""}
                find $out -type l ! -exec test -e {} \; -delete
              '';
            });
          };
        };
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            nix-ros-overlay.overlays.default
            cudaOverlay
          ];
        };
        acados = pkgs.callPackage ./acados.nix {};
      in {
        devShells.default = pkgs.mkShell {
          name = "ROS";
          shellHook = ''zsh'';

          packages = [
            # C++ Tools
            gcc
            libgcc
            gnumake
            cmake
            extra-cmake-modules
            clang-tools
            # Dependencies
            pkgs.ncurses
            pkgs.librealsenseWithCuda
            pkgs.tbb_2021_5
            pkgs.opencv4
            pkgs.cudaPackages.cudatoolkit
            pkgs.cudaPackages.cudnn
            pkgs.cudaPackages.tensorrt
            acados
            pkgs.libGLU
            pkgs.qt5.full
            pkgs.nlohmann_json
            pkgs.eigen
            (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
              pyqt5 numpy opencv4 pyyaml pandas pyopengl cryptography twisted pillow
            ]))
            (with pkgs.rosPackages.noetic; buildEnv {
              paths = [
                pluginlib
                ros-core
                rospy
                roscpp
                cv-bridge
                tf2
                tf
                image-transport
                geometry-msgs
                tf2-geometry-msgs
              ];
            })
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            "${pkgs.cudaPackages.cudatoolkit}/lib"
            "${pkgs.cudaPackages.cudnn}/lib"
            "${pkgs.cudaPackages.tensorrt}/lib"
            "${acados}/source/lib"
          ];

          TBB_DIR = "${pkgs.tbb}/lib/cmake/TBB";
          nlohmann_json_DIR = "${pkgs.nlohmann_json}/share/cmake/nlohmann_json";
          Eigen3_DIR = "${pkgs.eigen}/share/eigen3/cmake";
          ACADOS_SOURCE_DIR = "${acados}/source";
        };
      });

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
