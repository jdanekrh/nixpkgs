{ stdenv, fetchurl, makeWrapper, glib
, fontconfig, patchelf, libXext, libX11
, freetype, libXrender, rpmextract, zlib
}:

let
  arch = if stdenv.system == "x86_64-linux" then "x86_64"
    else if stdenv.system == "i686-linux" then "i386"
    else throw "Spideroak client for: ${stdenv.system} not supported!";

  interpreter = if stdenv.system == "x86_64-linux" then "ld-linux-x86-64.so.2"
    else if stdenv.system == "i686-linux" then "ld-linux.so.2"
    else throw "Spideroak client for: ${stdenv.system} not supported!";

  sha256 = if stdenv.system == "x86_64-linux" then "ed8fe0f91ca559af27b9fb1043c40cae199db4cc29939a45496ff4c390381c1e"
    else if stdenv.system == "i686-linux" then "03nm1bxjy0c906aalx8y830cigmj1fxdcmjx9x9lv1lyfi3mqmvf"
    else throw "Spideroak client for: ${stdenv.system} not supported!";

  ldpath = stdenv.lib.makeLibraryPath [
    glib fontconfig libXext libX11 freetype libXrender zlib
  ];

  version = "6.1.4";

in stdenv.mkDerivation {
  name = "spideroakgroups-${version}";

  src = fetchurl {
    name = "spideroakgroups-${version}-${arch}";
    url = "https://spideroak.com/getbuild?platform=fedora&arch=${arch}&brand=so.blue&version=${version}";
    inherit sha256;
  };

  sourceRoot = ".";

  unpackCmd = "rpmextract $curSrc";

  installPhase = ''
    mkdir "$out"
    cp -r "./"* "$out"
    mkdir "$out/bin"
    rm "$out/usr/bin/SpiderOakGroups"
    patchelf --set-interpreter ${stdenv.glibc}/lib/${interpreter} \
      "$out/opt/SpiderOak Groups/lib/SpiderOakGroups"
          
    # File "PyQt4/QtGui.py", line 17, in _bbfreeze_import_dynamic_module
    # ImportError: /nix/store/jlydjilcslwajqhn0s6b43vjvinsxm4k-spideroakgroups-6.1.4/opt/SpiderOak Groups/lib/libz.so.1: version
    # `ZLIB_1.2.9' not found (required by /nix/store/781s9dc59hf16279503nbx55wwjz9v65-libpng-apng-1.6.28/lib/libpng16.so.16)
    RPATH="${ldpath}:$out/opt/SpiderOak Groups/lib"  # prefer system libraries over embedded to resolve error above
    makeWrapper "$out/opt/SpiderOak\ Groups/lib/SpiderOakGroups" $out/bin/spideroakgroups --set LD_LIBRARY_PATH "$RPATH" \
      --set QT_PLUGIN_PATH "$out/opt/SpiderOak\ Groups/lib/plugins/" \
      --set SpiderOak_EXEC_SCRIPT $out/bin/spideroakgroups
  '';

  buildInputs = [ rpmextract patchelf makeWrapper ];

  meta = {
    homepage = "https://spideroak.com";
    description = "Secure online backup and sychronization for enterprise";
    license = stdenv.lib.licenses.unfree;
    maintainers = with stdenv.lib.maintainers; [ amorsillo ];
    platforms = stdenv.lib.platforms.linux;
  };
}

