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
            cudaSupport = true;
            permittedInsecurePackages = [
              "freeimage-unstable-2021-11-01"
            ];
          };
          overlays = [
            nix-ros-overlay.overlays.default
            (final: prev: {
              opencv = prev.opencv.overrideAttrs (old: {
                cmakeFlags = old.cmakeFlags ++ [
                  (prev.lib.cmakeBool "WITH_CUDA" true)
                  (prev.lib.cmakeBool "CUDA_FAST_MATH" true)
                  (prev.lib.cmakeFeature "CUDA_ARCH_BIN" "7.5")
                  (prev.lib.cmakeFeature "CUDA_NVCC_FLAGS" "-allow-unsupported-compiler")
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
            # Graphics drivers
            pkgs.mesa
            pkgs.libglvnd
            pkgs.vulkan-loader
            pkgs.vulkan-validation-layers
            pkgs.glfw
            pkgs.qt5.full
            pkgs.linuxPackages.nvidia_x11
            pkgs.libGLU
            pkgs.libGL
            # Dependencies
            pkgs.udev
            pkgs.ncurses
            pkgs.librealsenseWithCuda
            pkgs.tbb_2021_5
            pkgs.nlohmann_json
            pkgs.eigen
            pkgs.cudaPackages.tensorrt_8_6
            pkgs.opencv
            pkgs.acados
            pkgs.ncnn
            pkgs.hwloc
            pkgs.xwayland
            # Python
            (pkgs.python3.withPackages (python-pkgs: with python-pkgs; [
              setuptools pyqt5 numpy pyyaml pandas pyopengl cryptography twisted pillow scipy networkx matplotlib
            ]))
            # ROS
            (with pkgs.rosPackages.jazzy; buildEnv {
              paths = [
                colcon
                ament-cmake-core
                python-cmake-module
                # ros extras
                ros-core
                rclpy
                rclcpp
                cv-bridge
                tf2
                image-transport
                geometry-msgs
                tf2-geometry-msgs
                gazebo-msgs
                robot-localization
                # ros gz
                gz-cmake-vendor
                gz-common-vendor
                gz-dartsim-vendor
                gz-fuel-tools-vendor
                gz-gui-vendor
                gz-launch-vendor
                gz-math-vendor
                gz-msgs-vendor
                gz-ogre-next-vendor
                gz-physics-vendor
                gz-plugin-vendor
                gz-rendering-vendor
                gz-sensors-vendor
                gz-sim-vendor
                gz-tools-vendor
                gz-transport-vendor
                gz-utils-vendor
              ];
            })
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            "${pkgs.cudatoolkit}/lib"
            "${pkgs.cudaPackages.tensorrt_8_6}/lib"
            "${pkgs.opencv}/lib"
            "${pkgs.acados}/lib"
          ];
          
          TRT_LIBPATH = "${pkgs.cudaPackages.tensorrt_8_6}/lib";
          TBB_DIR = "${pkgs.tbb}/lib/cmake/TBB";
          nlohmann_json_DIR = "${pkgs.nlohmann_json}/share/cmake/nlohmann_json";
          Eigen3_DIR = "${pkgs.eigen}/share/eigen3/cmake";
          OpenCV_DIR = "${pkgs.opencv}/lib/cmake/opencv4";
          OpenCV_INCLUDE_DIRS = "${pkgs.opencv}/include/opencv4";
          acados_DIR = "${pkgs.acados}/cmake";
          ncnn_DIR = "${pkgs.ncnn}/lib/cmake/ncnn";
          GDK_BACKEND="x11";
          QT_QPA_PLATFORM="xcb";
          SDL_VIDEODRIVER="x11";
        };
      });

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
