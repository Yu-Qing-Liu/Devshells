{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;  # For CUDA if needed
        };

        ultralytics-thop = pkgs.callPackage ./ultralytics-thop.nix {};
        ultralytics = pkgs.callPackage ./ultralytics.nix {};

        pythonEnv = pkgs.python3.withPackages (ps: [
          ultralytics
          ultralytics-thop
          ps.torch
          ps.torchvision
          ps.opencv4
          ps.python-lsp-server
        ]);
        
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            pythonEnv
            pkgs.python3Packages.ipython
          ];

          # Environment variables for CUDA
          shellHook = ''
            export SHELL=/run/current-system/sw/bin/zsh
            export LD_LIBRARY_PATH=${pkgs.stdenv.cc.cc.lib}/lib:$LD_LIBRARY_PATH
            export PYTHONPATH=${pythonEnv}/${pythonEnv.sitePackages}:$PYTHONPATH
          '';
        };
      });
}
