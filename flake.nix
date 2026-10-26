{
  description = "lemonade's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # Android Studio だけ unstable から取るための入力 (home.nix 参照)。
    # nixpkgs は安定ブランチに Android Studio のメジャー更新を backport しない
    # ので、26.05 のままだと Panda 4 (2026-05) で止まる。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    shojiwm.url = "github:bea4dev/ShojiWM";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # RaspberryPi Pico (RP2040) 開発環境。devShell と udev 設定を単体 flake に
    # 切り出してある (友人に nix develop github:lemonade-2061/pico-dev で渡せる形)。
    # 中身を直したら push してから `nix flake update pico-dev`。
    pico-dev = {
      url = "github:lemonade-2061/pico-dev";
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
        # Pico は単体 flake (pico-dev) 側が本体
        pico = inputs.pico-dev.devShells.x86_64-linux.default;
      };

    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix

        # Pico: udev ルール + シリアルのグループ (devShell は上の devShells.pico)
        inputs.pico-dev.nixosModules.default
        { programs.pico-dev = { enable = true; users = [ "lemonade" ]; }; }

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
