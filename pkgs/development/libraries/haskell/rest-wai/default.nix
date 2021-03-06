# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, caseInsensitive, httpTypes, mimeTypes, mtl, restCore
, restTypes, text, unorderedContainers, utf8String, wai
}:

cabal.mkDerivation (self: {
  pname = "rest-wai";
  version = "0.1.0.2";
  sha256 = "06wnazy0262b2875q4km2xy9zz7l681vlfj3ny1ha9valnqr3q6w";
  buildDepends = [
    caseInsensitive httpTypes mimeTypes mtl restCore restTypes text
    unorderedContainers utf8String wai
  ];
  meta = {
    description = "Rest driver for WAI applications";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
