{ pkgs }:
let
  ultralytics-thop = pkgs.callPackage ./ultralytics-thop.nix {};
in
  pkgs.python3Packages.buildPythonPackage rec {
  pname = "ultralytics";
  version = "8.3.61";
  src = pkgs.python3Packages.fetchPypi {
    inherit pname version;
    sha256 = "6cbed15f2447ff93d37cafa61f1816ca5bf333bec8b73a2379ea8e87cdc5ccaf";
  };
  pyproject = true;
  propagatedBuildInputs = with pkgs.python3Packages; [
    requests
    setuptools
    matplotlib
    numpy
    opencv-python
    pandas
    pillow
    psutil
    py-cpuinfo
    pyyaml
    scipy
    seaborn
    torch
    torchvision
    tqdm
    ultralytics-thop
  ];
  preBuild = ''
    sed -i '/torchvision>=0.9.0/d' pyproject.toml
  '';
  nativeBuildInputs = with pkgs.python3Packages; [
    setuptools 
    pip 
  ];
  meta = {
    description = "Ultralytics";
    homepage = "https://github.com/ultralytics/ultralytics";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.all;
  };
}
