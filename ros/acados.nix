{ lib, stdenv, cmake, fetchFromGitHub, python3, blas, lapack, nlohmann_json, eigen, openblas }:

stdenv.mkDerivation rec {
  pname = "acados";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "acados";
    repo = "acados";
    rev = "v${version}";
    hash = "sha256-AwwsUBCn29WBuTFSgl0spAnQunk14t3N5T2anS8wiJQ=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    python3
    blas
    lapack
    nlohmann_json
    eigen
    openblas
    python3.pkgs.numpy
    python3.pkgs.setuptools
  ];

  cmakeFlags = [
    "-DACADOS_WITH_QPOASES=ON"
    "-DACADOS_EXAMPLES=ON"
    "-DHPIPM_TARGET=GENERIC"
    "-DBLASFEO_TARGET=GENERIC"
  ];

  preConfigure = ''
    sed -i 's/BLASFEO_TARGET = .*/BLASFEO_TARGET = GENERIC/' Makefile.rule
    sed -i 's/ACADOS_WITH_QPOASES = .*/ACADOS_WITH_QPOASES = 1/' Makefile.rule
    sed -i 's/HPIPM_TARGET = .*/HPIPM_TARGET = GENERIC/' Makefile.rule
  '';

  buildPhase = ''
    cd ..
    make shared_library
    cd build
    make install
  '';

  installPhase = ''
    # Copy shared libraries
    mkdir -p $out/source
    mv ../* $out/source
  '';

  meta = with lib; {
    description = "A modular open-source framework for fast embedded optimal control";
    homepage = "https://github.com/acados/acados";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
