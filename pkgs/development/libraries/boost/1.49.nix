{ stdenv, fetchurl, icu, expat, zlib, bzip2, python
, enableRelease ? true
, enableDebug ? false
, enableSingleThreaded ? false
, enableMultiThreaded ? true
, enableShared ? true
, enableStatic ? false
, enablePIC ? false
, enableExceptions ? false
}:

let

  variant = stdenv.lib.concatStringsSep ","
    (stdenv.lib.optional enableRelease "release" ++
     stdenv.lib.optional enableDebug "debug");

  threading = stdenv.lib.concatStringsSep ","
    (stdenv.lib.optional enableSingleThreaded "single" ++
     stdenv.lib.optional enableMultiThreaded "multi");

  link = stdenv.lib.concatStringsSep ","
    (stdenv.lib.optional enableShared "shared" ++
     stdenv.lib.optional enableStatic "static");

  # To avoid library name collisions
  finalLayout = if ((enableRelease && enableDebug) ||
    (enableSingleThreaded && enableMultiThreaded) ||
    (enableShared && enableStatic)) then
    "tagged" else "system";

  cflags = if enablePIC && enableExceptions then
             "cflags=-fPIC -fexceptions cxxflags=-fPIC linkflags=-fPIC"
           else if enablePIC then
             "cflags=-fPIC cxxflags=-fPIC linkflags=-fPIC"
           else if enableExceptions then
             "cflags=-fexceptions"
           else
             "";
in

stdenv.mkDerivation {
  name = "boost-1.49.0";

  meta = {
    homepage = "http://boost.org/";
    description = "Boost C++ Library Collection";
    license = "boost-license";

    platforms = stdenv.lib.platforms.unix;
    maintainers = [ stdenv.lib.maintainers.simons ];
  };

  src = fetchurl {
    url = "mirror://sourceforge/boost/boost_1_49_0.tar.bz2";
    sha256 = "0g0d33942rm073jgqqvj3znm3rk45b2y2lplfjpyg9q7amzqlx6x";
  };

  # See <http://svn.boost.org/trac/boost/ticket/4688>.
  patches = [
    ./CVE-2013-0252.patch # https://svn.boost.org/trac/boost/ticket/7743
    ./boost_filesystem_post_1_49_0.patch
    ./time_utc.patch
    ./boost-149-cstdint.patch
  ] ++ (stdenv.lib.optional stdenv.isDarwin ./boost-149-darwin.patch );

  enableParallelBuilding = true;

  buildInputs = [icu expat zlib bzip2 python];

  configureScript = "./bootstrap.sh";
  configureFlags = "--with-icu=${icu} --with-python=${python}/bin/python";

  buildPhase = "./b2 -j$NIX_BUILD_CORES -sEXPAT_INCLUDE=${expat}/include -sEXPAT_LIBPATH=${expat}/lib --layout=${finalLayout} variant=${variant} threading=${threading} link=${link} ${cflags} install";

  installPhase = ":";

  crossAttrs = rec {
    buildInputs = [ expat.crossDrv zlib.crossDrv bzip2.crossDrv ];
    # all buildInputs set previously fell into propagatedBuildInputs, as usual, so we have to
    # override them.
    propagatedBuildInputs = buildInputs;
    # We want to substitute the contents of configureFlags, removing thus the
    # usual --build and --host added on cross building.
    preConfigure = ''
      export configureFlags="--prefix=$out --without-icu"
    '';
    buildPhase = ''
      set -x
      cat << EOF > user-config.jam
      using gcc : cross : $crossConfig-g++ ;
      EOF
      ./b2 -j$NIX_BUILD_CORES -sEXPAT_INCLUDE=${expat.crossDrv}/include -sEXPAT_LIBPATH=${expat.crossDrv}/lib --layout=${finalLayout} --user-config=user-config.jam toolset=gcc-cross variant=${variant} threading=${threading} link=${link} ${cflags} --without-python install
    '';
  };
}
