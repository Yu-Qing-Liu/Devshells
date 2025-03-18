{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/develop";
    nix-ros-overlay.inputs.nixpkgs.follows = "nixpkgs-stable";
    nixpkgs.follows = "nixpkgs-stable";
  };

  outputs = { self, nix-ros-overlay, nixpkgs, nixpkgs-stable }:
    nix-ros-overlay.inputs.flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
          overlays = [
            nix-ros-overlay.overlays.default
            (final: prev: {
              opencv = prev.opencv.overrideAttrs (old: {
                buildInputs = old.buildInputs ++ [
                  final.cudaPackages.cudatoolkit
                ];
                cmakeFlags = old.cmakeFlags ++ [
                  "-DWITH_CUDA=ON"
                  "-DCUDA_ARCH_BIN=7.5"
                ];
              });
              acados = prev.callPackage ./acados.nix {};
            })
          ];
        };
      in {
        devShells.default = pkgs.mkShell {
          name = "ROS";
          shellHook = ''zsh'';

          packages = [
            # C++ Tools
            pkgs.stdenv.cc
            pkgs.cmake
            pkgs.gnumake
            pkgs.clang-tools
            # Dependencies
            pkgs.udev
            pkgs.ncurses
            pkgs.librealsenseWithCuda
            pkgs.tbb_2021_5
            pkgs.libGLU
            pkgs.qt5.full
            pkgs.nlohmann_json
            pkgs.eigen
            pkgs.cudatoolkit
            pkgs.cudaPackages.tensorrt_8_6
            pkgs.opencv
            pkgs.acados
            pkgs.ncnn
            (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
              setuptools pyqt5 numpy pyyaml pandas pyopengl cryptography twisted pillow
            ]))
            (with pkgs.rosPackages.noetic; buildEnv {
              paths = [
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
                robot-localization
              ];
            })
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            "${pkgs.cudatoolkit}/lib"
            "${pkgs.cudaPackages.tensorrt_8_6}/lib"
            "${pkgs.opencv}/lib"
            "${pkgs.acados}/lib"
          ];

          TBB_DIR = "${pkgs.tbb}/lib/cmake/TBB";
          nlohmann_json_DIR = "${pkgs.nlohmann_json}/share/cmake/nlohmann_json";
          Eigen3_DIR = "${pkgs.eigen}/share/eigen3/cmake";
          OpenCV_DIR = "${pkgs.opencv}/lib/cmake/opencv4";
          OpenCV_INCLUDE_DIRS = "${pkgs.opencv}/include/opencv4";
          acados_DIR = "${pkgs.acados}/cmake";
        };
      });

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
