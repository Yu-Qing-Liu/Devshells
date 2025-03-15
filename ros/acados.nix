{ lib, stdenv, cmake, fetchFromGitHub, python3, blas, lapack, nlohmann_json, eigen, openblas }:

stdenv.mkDerivation rec {
  pname = "acados";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "acados";
    repo = "acados";
    rev = "v${version}";
    hash = "sha256-0aiwgy5x8jpmzgvp683625v68iwxpaak1nx261xv25al6jf9rs78=";
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
    "-DCMAKE_INSTALL_PREFIX=${placeholder "out"}"
    "-DACADOS_INSTALL_DIR=${placeholder "out"}"
    "-DBUILD_SHARED_LIBS=ON"
  ];

  preConfigure = ''
    # Apply Makefile.rule modifications
    substituteInPlace Makefile.rule \
      --replace "BLASFEO_TARGET = AUTO" "BLASFEO_TARGET = GENERIC" \
      --replace "ACADOS_WITH_QPOASES = 0" "ACADOS_WITH_QPOASES = 1"
  '';

  buildPhase = ''
    mkdir -p build
    cd build
    cmake .. $cmakeFlags
    make -j $NIX_BUILD_CORES
    cd ..
    make shared_library
    cd build
    make -j $NIX_BUILD_CORES
  '';

  installPhase = ''
    mkdir -p $out/lib $out/include
    # Install libraries
    find . -name '*.a' -exec cp {} $out/lib \;
    find . -name '*.so' -exec cp {} $out/lib \;
    # Install headers
    cp -r ../include/* $out/include/
    # Install Python bindings
    cd ../interfaces/acados_template
    ${python3.interpreter} setup.py install --prefix=$out
  '';

  postFixup = ''
    patchelf --set-rpath "${lib.makeLibraryPath [ blas lapack openblas ]}:$out/lib" $out/lib/*.so
  '';

  meta = with lib; {
    description = "A modular open-source framework for fast embedded optimal control";
    homepage = "https://github.com/acados/acados";
    license = licenses.asl20;
    platforms = platforms.all;
  };
}
