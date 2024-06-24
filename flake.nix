{
  description = "friction.graphics nix flake";
  inputs.nixpkgs.url = "nixpkgs/nixos-24.05";
  inputs.utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
        version = "v0.9.6";
      in {
        packages.frictionGraphics = pkgs.clangStdenv.mkDerivation {
          pname = "friction.graphics";
          inherit version;
          src = pkgs.fetchgit {
            url = "https://github.com/friction2d/friction";
            rev = version;
            sha256 = "sha256-QjwkijsTAEEN1VqGtIfsNsHTM1DIRUp+hfABuXoj+nU=";
            fetchSubmodules = true;
          };
          buildInputs = with pkgs; [
            expat
            ffmpeg_4-full
            fontconfig
            freetype
            glib
            gn
            harfbuzzFull
            icu
            libGL
            libjpeg_turbo
            libpng
            libsForQt5.qscintilla
            libunwind
            libwebp
            ninja
            pcre2
            python3
            qt5Full
            xorg.libX11
            zlib
          ];
          nativeBuildInputs = with pkgs; [ clang cmake pkg-config ];
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_INSTALL_PREFIX=bin"
            "-DHARFBUZZ_INCLUDE_DIRS=${pkgs.harfbuzz.dev}/include"
            #"-DCMAKE_CXX_COMPILER=${pkgs.clang}/bin/clang++"
            #"-DCMAKE_C_COMPILER=${pkgs.clang}/bin/clang"
            "-DQSCINTILLA_INCLUDE_DIRS=${pkgs.qscintilla}/include"
            "-DQSCINTILLA_LIBRARIES_DIRS=${pkgs.qscintilla}/lib/"
            "-DQSCINTILLA_LIBRARIES=libqscintilla2.so"

            "-G Ninja"
          ];
          patchPhase = ''
            sed -i 's|''${SKIA_SRC}/bin/gn)|${pkgs.gn}/bin/gn)|' src/engine/CMakeLists.txt
            sed -i 's|fontconfig|${pkgs.fontconfig.lib}/lib/libfontconfig.so|' src/cmake/friction-common.cmake
            grep -rl 'hb' | xargs sed -Ei 's/(["<])(hb.*\.h)/\1harfbuzz\/\2/' 
          '';
          buildPhase = ''
            export VERBOSE=1
            cmake --build . --config Release
          '';
          installPhase = ''
            mkdir -p $out/bin
            cp src/app/friction $out/friction
          '';

        };
        packages.default = self.packages.${system}.frictionGraphics;
      });
}

