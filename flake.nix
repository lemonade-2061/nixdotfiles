{
  description = "lemonade's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    shojiwm.url = "git+file:///home/lemonade/git-clone/ShojiWM";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SDDM テーマ集 (~/git-clone/qylock にローカルclone)
    qylock = {
      url = "git+file:///home/lemonade/git-clone/qylock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # C/C++学習用 (競プロ・自作malloc等): nix develop ~/nixos#c
    devShells.x86_64-linux.c =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in pkgs.mkShell {
        packages = with pkgs; [
          gcc
          gdb
          valgrind
          gnumake
          clang-tools # clangd (エディタのLSP用)
          man-pages # man 3 malloc 等
          man-pages-posix
        ];
        shellHook = ''
          echo "C dev shell: gcc / gdb / valgrind / clangd"
          echo "  例: gcc -g -Wall -Wextra -fsanitize=address,undefined main.c"
        '';
      };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        inputs.qylock.nixosModules.default
        inputs.shojiwm.nixosModules.default
        {
          programs.shojiwm = {
            enable = true;
            initConfig = { enable = true; users = [ "lemonade" ]; };
          };
        }

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "hm-backup";
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.lemonade = import ./home.nix;
        }
      ];
    };
  };
}
