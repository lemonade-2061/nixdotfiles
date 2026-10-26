{
    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    outputs = { nixpkgs, ... }:
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        # CRAN の "." は "_" に置換 (data.table -> data_table)
        rPkgs = with pkgs.rPackages; [ tidyverse data_table languageserver ];
      in {
        devShells.${system}.default = pkgs.mkShell {
          packages = [
            (pkgs.rWrapper.override { packages = rPkgs; })
            (pkgs.rstudioWrapper.override { packages = rPkgs; })
          ];
        };
      };
  }
