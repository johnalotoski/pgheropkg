with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "env";
  buildInputs = [
    ruby.devEnv
    git
    postgresql
    libxml2
    libxslt
    pkg-config
    bundix
    gnumake
  ];
}
