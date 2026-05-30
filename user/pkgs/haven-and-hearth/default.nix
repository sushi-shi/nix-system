{ lib, stdenv, fetchurl, makeWrapper, jdk8, libXxf86vm }:
stdenv.mkDerivation rec {
  pname = "haven-and-hearth";
  version = "0.0.0";

  src = fetchurl {
    url = "http://www.havenandhearth.com/java/hafen-launcher.jar";
    sha256 = "sha256-a26k0NckzFVf1pIw3gmKDFxJ44vBFcGxoGyMSKT0QtU=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jdk8 libXxf86vm ];

  installPhase = ''
    mkdir -p $out/bin $out/lib/natives
    cp ${src} $out/hafen-launcher.jar
    cp -r ${./natives/linux-amd64}/. $out/lib/natives/

    makeWrapper ${jdk8}/bin/java $out/bin/hafen \
      --add-flags "-Djava.library.path=$out/lib/natives:${libXxf86vm}/lib" \
      --add-flags "-jar $out/hafen-launcher.jar"
  '';

  meta = with lib; {
    description = "Haven & Hearth MMORPG set in a world inspired by Slavic and Germanic myth.";
    license = with licenses; [ unfree ];
    maintainers = with maintainers; [ ];
  };
}
