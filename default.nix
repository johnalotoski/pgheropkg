{ pkgs ? import <nixpkgs> {} }: with pkgs;
let
  env = bundlerEnv {
    name = "pghero";
    gemdir = ./.;
    gemConfig = pkgs.defaultGemConfig // {
      pg_query = attrs: let
        libpg_query = fetchurl {
          url = "https://codeload.github.com/lfittl/libpg_query/tar.gz/10-1.0.1";
          sha256 = "0m5jv134hgw2vcfkqlnw80fr3wmrdvgrvk1ndcx9s44bzi5nsp47";
        };
      in {
        dontBuild = false;
        postPatch = ''
          substituteInPlace ext/pg_query/extconf.rb \
            --replace "'https://codeload.github.com/lfittl/libpg_query/tar.gz/' + LIB_PG_QUERY_TAG" \
                      "'${libpg_query}'"
        '';
      };
    };
  };

  pghero = { stdenv, fetchFromGitHub, bundlerEnv, writeShellScriptBin }: stdenv.mkDerivation rec {
    pname = "pghero";
    version = (import ./gemset.nix).pghero.version;
    src = fetchFromGitHub {
      owner = "pghero";
      repo = "pghero";
      rev = "v2.4.1";
      sha256 = "0wr5r9fj8hw1p572bni68wy5fp02zg2hadpc1c2kshkwin9dn3gv";
    };

    buildInputs = [ env ];

    RAILS_ENV = "production";
    DATABASE_URL = "postgresql://user:pass@127.0.0.1/dbname";
    SECRET_TOKEN = "dummytoken";

    buildPhase = ''
      mkdir -p $out/lib $out/bin
      cp -r $src $out/lib/pghero/
      chmod u+rw -R $out
      cd $out/lib/pghero
      rake assets:precompile
      rm -rf tmp
    '';

    installPhase = ''
      echo "#!${stdenv.shell}" > $out/bin/pghero
      echo "cd $out/lib/pghero" >> $out/bin/pghero
      echo "${env}/bin/puma -C config/puma.rb" >> $out/bin/pghero
      chmod +x $out/bin/pghero
    '';

    meta = with stdenv.lib; {
      description = "Performance dashboard for PostgreSQL";
      homepage = "https://pghero.org/";
      license = licenses.mit;
      platforms = platforms.linux;
      maintainers = with maintainers; [ manveru ];
    };
  };
in (callPackage pghero {})
