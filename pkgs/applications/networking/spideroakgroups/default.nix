{ stdenv, fetchurl, makeWrapper, patchelf
, fontconfig, freetype, glib, libICE, libSM
, libX11, libXext, libXrender, zlib, rpmextract
}:

let
  interpreter = if stdenv.system == "x86_64-linux" then "ld-linux-x86-64.so.2"
    else throw "Spideroak client for: ${stdenv.system} not supported!";

  ldpath = stdenv.lib.makeLibraryPath [
    fontconfig freetype glib libICE libSM
    libX11 libXext libXrender zlib
  ];

  version = "7.5.0.1";

in stdenv.mkDerivation {
  name = "spideroakgroups-${version}";

  src = fetchurl {
    name = "SpiderOakGroups.${version}.x86_64.rpm";
    url = "https://spideroak.com/release/so.blue/rpm_x64";
    sha256 = "0h804yhx0vjhb5gg98knqa5gq8cw6ghrnknhzkizwl83n5fxvkrn";
  };

  sourceRoot = ".";

  unpackCmd = "rpmextract $curSrc";

  installPhase = ''
    mkdir "$out"
    cp -r "./"* "$out"
    mkdir "$out/bin"
    mv $out/usr/share $out/
    rm "$out/usr/bin/SpiderOakGroups"
    rmdir $out/usr/bin || true
    
    rm -f "$out/opt/SpiderOak Groups/lib/libz*"
    
    patchelf --set-interpreter ${stdenv.glibc}/lib/${interpreter} \
      "$out/opt/SpiderOak Groups/lib/SpiderOakGroups"
          
    # File "PyQt4/QtGui.py", line 17, in _bbfreeze_import_dynamic_module
    # ImportError: /nix/store/jlydjilcslwajqhn0s6b43vjvinsxm4k-spideroakgroups-6.1.4/opt/SpiderOak Groups/lib/libz.so.1: version
    # `ZLIB_1.2.9' not found (required by /nix/store/781s9dc59hf16279503nbx55wwjz9v65-libpng-apng-1.6.28/lib/libpng16.so.16)
    RPATH="${ldpath}:$out/opt/SpiderOak Groups/lib"  # prefer system libraries over embedded to resolve error above
    makeWrapper "$out/opt/SpiderOak Groups/lib/SpiderOakGroups" $out/bin/spideroakgroups \
      --set LD_LIBRARY_PATH "$RPATH" \
      --set QT_PLUGIN_PATH "$out/opt/SpiderOak Groups/lib/plugins/" \
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

