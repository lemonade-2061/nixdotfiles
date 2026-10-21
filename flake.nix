{
  description = "lemonade's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    shojiwm.url = "github:bea4dev/ShojiWM";

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
    # 開発環境は shells/ に分けてある (nix develop ~/nixos#<名前>)。
    devShells.x86_64-linux =
      let pkgs = nixpkgs.legacyPackages.x86_64-linux;
      in {
        c = import ./shells/c.nix { inherit pkgs; };
        pico = import ./shells/pico.nix { inherit pkgs; };
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
