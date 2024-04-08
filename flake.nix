{
  description = "Transky-book's Nix flake";
  nixConfig =
    {
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        # "https://mirrors.cernet.edu.cn/nix-channels/store"
        # "https://mirrors.bfsu.edu.cn/nix-channels/store"
        "https://cache.nixos.org/"
      ];
      extra-substituters = [
        "https://cryolitia.cachix.org"
      ];
      extra-trusted-public-keys = [
        "cryolitia.cachix.org-1:/RUeJIs3lEUX4X/oOco/eIcysKZEMxZNjqiMgXVItQ8="
      ];
    };
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nur-cryolitia = {
      url = "github:Cryolitia/nur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nur-cryolitia }:
    {
      packages.x86_64-linux.default =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              (final: prev: {
                nur-cryolitia = nur-cryolitia.packages."${prev.system}";
              })
            ];
          };
        in
        pkgs.callPackage (
          { lib
          , stdenvNoCC
          , calibre
          , mdbook
          , mdbook-epub
          , nur-cryolitia
          , source-han-serif
          , typst
          }:

          stdenvNoCC.mkDerivation
            rec {
              pname = "transky-book";
              version = "unstable";

              src = ./.;

              nativeBuildInputs = [
                calibre
                mdbook
                mdbook-epub
                nur-cryolitia.mdbook-typst-pdf
                source-han-serif
                typst
              ];

              buildPhase = ''
                runHook preBuild

                find src/ -type f -name "*.md" ! -path "src/index.md" -exec \
                  sed -i "/^---$/,/^---$/d" {} \;

                mdbook build

                mkdir -p book/mobi
                ebook-convert book/epub/药娘的天空.epub book/mobi/药娘的天空.mobi

                export TYPST_FONT_PATHS=${source-han-serif}/share/fonts/opentype/source-han-serif
                typst compile book/typst-pdf/药娘的天空.typ

                runHook postBuild
              '';

              installPhase = ''
                runHook preInstall

                mkdir -p $out/share/transky-book
                cp -r book $out/share/transky-book/

                runHook postInstall
              '';

              meta = with lib; {
                description = "药娘的天空";
                homepage = "https://github.com/transky-book/transky";
                license = licenses.cc-by-nc-sa-40;
                maintainers = with maintainers; [ Cryolitia ];
              };
            }
        ) {};
    };
}
