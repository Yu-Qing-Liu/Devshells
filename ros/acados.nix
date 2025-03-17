{ lib, stdenv, cmake, fetchFromGitHub, python3, blas, lapack, nlohmann_json, eigen, openblas }:

stdenv.mkDerivation rec {
  pname = "acados";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "acados";
    repo = "acados";
    rev = "fd25099ceb0b66a80147b262db162752fdddb6dc";
    hash = "sha256-tL5wz4J3pL2S9KZbEdcR9mv2EMgSzWXGseyfzYQlGLA=";
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

  env.NIX_CFLAGS_COMPILE = lib.concatStringsSep " " [
    "-Wno-error=implicit-function-declaration"
    "-Wno-error=incompatible-pointer-types"
    "-Wno-error=int-conversion"
  ];

  preConfigure = ''
    sed -i 's/BLASFEO_TARGET = .*/BLASFEO_TARGET = GENERIC/' Makefile.rule
    sed -i 's/ACADOS_WITH_QPOASES = .*/ACADOS_WITH_QPOASES = 1/' Makefile.rule
    sed -i 's/HPIPM_TARGET = .*/HPIPM_TARGET = GENERIC/' Makefile.rule
    sed -i 's/#CFLAGS += -DNDEBUG/CFLAGS += -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion/' Makefile.rule
    echo "CFLAGS += -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion" >> ./external/hpmpc/Makefile.rule
    echo "CFLAGS += -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion" >> ./external/hpipm/Makefile.rule
    echo "CFLAGS += -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -Wno-error=int-conversion" >> ./external/blasfeo/Makefile.rule
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
