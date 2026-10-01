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

    # RaspberryPi Pico (RP2040) 開発環境: nix develop ~/nixos#pico
    #
    # 「組込みシステム」の手順書 (鷹合研究室・Windows版) は VsCode の
    # 「Raspberry Pi Pico」拡張機能に SDK 取得とビルドをやらせるが、ここでは
    #   SDK/ツールチェーン → この devShell (宣言的・~/.pico-sdk は作らない)
    #   Compile / Run / シリアルモニタ → 下の pico-* コマンド
    # に置き換える。エディタは何でもよい (nvim + clangd を想定)。
    devShells.x86_64-linux.pico =
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;

        # withSubmodules: TinyUSB を含む。pico_stdio_usb (printf を USB シリアルへ
        # 出す = 手順書の「シリアルモニター」) が TinyUSB 必須なので必ず有効にする。
        picoSdk = pkgs.pico-sdk.override { withSubmodules = true; };
        sdkPath = "${picoSdk}/lib/pico-sdk";

        # 手順書の「新規プロジェクトの作り方」に相当。拡張機能の New Project が
        # 吐くのと同じ構成 (CMakeLists.txt / <名前>.c / pico_sdk_import.cmake) を作る。
        pico-new = pkgs.writeShellApplication {
          name = "pico-new";
          runtimeInputs = [ pkgs.coreutils ];
          text = ''
            set -euo pipefail
            name="''${1:-}"
            if [ -z "$name" ]; then
              echo "usage: pico-new <プロジェクト名>   (例: pico-new test00)" >&2
              exit 1
            fi
            case "$name" in
              *[!A-Za-z0-9_-]*)
                echo "pico-new: 名前は半角英数と _ - のみ (日本語・空白はビルドエラーの原因)" >&2
                exit 1;;
            esac
            if [ -e "$name" ]; then
              echo "pico-new: '$name' はすでに存在します" >&2
              exit 1
            fi

            mkdir -p "$name"
            cd "$name"

            # SDK 同梱の import スクリプトをそのまま使う (PICO_SDK_PATH を解決する)
            cp "${sdkPath}/external/pico_sdk_import.cmake" .
            chmod +w pico_sdk_import.cmake

            cat > CMakeLists.txt <<EOF
            cmake_minimum_required(VERSION 3.13)

            set(CMAKE_C_STANDARD 11)
            set(CMAKE_CXX_STANDARD 17)
            # clangd (エディタの補完・エラー表示) が読む compile_commands.json を出す
            set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

            # 基板は Pico 1 (RP2040)。Pico2 を選ぶと書き込めないので注意。
            set(PICO_BOARD pico CACHE STRING "Board type")

            include(pico_sdk_import.cmake)

            project($name C CXX ASM)
            pico_sdk_init()

            add_executable($name $name.c)
            pico_set_program_name($name "$name")
            pico_set_program_version($name "0.1")

            # printf の行き先。USB シリアル (/dev/ttyACM0) に出す = pico-mon で読める。
            pico_enable_stdio_usb($name 1)
            pico_enable_stdio_uart($name 0)

            target_link_libraries($name
              pico_stdlib      # GPIO / タイマー / stdio
              hardware_adc     # 電圧計測 (w2_volt 等)
              hardware_pwm     # PWM 出力
            )

            # .uf2 (書き込み用ファイル) と .elf/.bin/.dis を build/ に生成する
            pico_add_extra_outputs($name)
            EOF

            cat > "$name.c" <<EOF
            #include <stdio.h>
            #include "pico/stdlib.h"

            #define LED_DELAY_MS 250

            int main(void) {
                stdio_init_all();

                gpio_init(PICO_DEFAULT_LED_PIN);
                gpio_set_dir(PICO_DEFAULT_LED_PIN, GPIO_OUT);

                while (true) {
                    gpio_put(PICO_DEFAULT_LED_PIN, 1);
                    sleep_ms(LED_DELAY_MS);
                    gpio_put(PICO_DEFAULT_LED_PIN, 0);
                    sleep_ms(LED_DELAY_MS);
                    printf("blink\n");
                }
            }
            EOF

            # clangd (エディタの補完・エラー表示) は cmake が build/ に吐く
            # compile_commands.json を読む。SDK が使うコンパイルフラグ
            # (-mcpu=cortex-m0plus -mthumb -std=gnu11 ...) は clang でもそのまま通る。
            #
            # newlib のヘッダを解決させるには clangd に --query-driver が必要だが、
            # これは CLI 専用オプションなので .clangd には書けない。
            # nvim 側 (dotfiles/nvim/lua/plugins/clangd.lua) で渡している。
            #
            # UnusedIncludes/MissingIncludes は切る。pico/stdlib.h のような
            # まとめヘッダ (中身を再 include するだけ) を「直接使っていない」と
            # 誤検出して毎回警告を出すため。
            cat > .clangd <<'EOF'
            CompileFlags:
              CompilationDatabase: build

            Diagnostics:
              UnusedIncludes: None
              MissingIncludes: None
            EOF

            # cd しただけで devShell に入るように (direnv)
            cat > .envrc <<'EOF'
            use flake /home/lemonade/nixos#pico
            EOF

            cat > .gitignore <<'EOF'
            build/
            .direnv/
            EOF

            echo "作成しました: $PWD"
            echo "  cd $name && direnv allow   # 初回のみ"
            echo "  pico-build   # ビルド (手順書の Compile)"
            echo "  pico-flash   # 書き込み  (手順書の RUN)"
            echo "  pico-mon     # シリアルモニタ"
          '';
        };

        # 手順書の「Compile」ボタン相当。cmake 構成は build/ が無いときだけ走る。
        pico-build = pkgs.writeShellApplication {
          name = "pico-build";
          runtimeInputs = [ pkgs.cmake pkgs.ninja ];
          text = ''
            set -euo pipefail
            [ -f CMakeLists.txt ] || { echo "pico-build: CMakeLists.txt が無い (プロジェクトの直下で実行して)" >&2; exit 1; }
            # 既定は Debug。手順書の「ビルドタイプ切り替え」に相当し、最適化による
            # 不具合を避けるため開発中は Debug のままでよい (BUILD_TYPE=Release で変更)。
            cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE="''${BUILD_TYPE:-Debug}"
            cmake --build build "$@"
            echo
            ls -1 build/*.uf2 2>/dev/null || echo "警告: .uf2 が生成されていません (pico_add_extra_outputs を確認)"
          '';
        };

        # 手順書の「RUN」ボタン相当。BOOTSEL 中の Pico に uf2 を書き込んで実行させる。
        pico-flash = pkgs.writeShellApplication {
          name = "pico-flash";
          runtimeInputs = [ pkgs.picotool ];
          text = ''
            set -euo pipefail
            uf2="''${1:-}"
            if [ -z "$uf2" ]; then
              # build 直下の .uf2 を自動で選ぶ
              set -- build/*.uf2
              [ -e "$1" ] || { echo "pico-flash: build/*.uf2 が無い。先に pico-build を実行して" >&2; exit 1; }
              [ "$#" -eq 1 ] || { echo "pico-flash: .uf2 が複数ある。ファイルを指定して: $*" >&2; exit 1; }
              uf2="$1"
            fi

            echo "書き込み: $uf2"
            # -f: 実行中プログラムが USB reset インタフェースを持てば自動で BOOTSEL に落とす
            #     (pico_enable_stdio_usb したプログラムなら手でボタンを押さなくてよい)
            # -x: 書き込み後にそのまま実行する
            if ! picotool load -f -x -v "$uf2"; then
              cat >&2 <<'MSG'

            書き込めませんでした。Pico を手動で BOOTSEL モードにしてから再実行してください:
              1. 基板の BOOTSEL ボタンを押したままにする
              2. 外部タクトスイッチ (28番 GND - 30番 RUN) を押して離す
              3. BOOTSEL ボタンから手を離す
            picotool info で認識されているか確認できます。
            MSG
              exit 1
            fi
          '';
        };

        # 手順書の「シリアルモニターの使い方」相当。Ctrl-t q で終了。
        pico-mon = pkgs.writeShellApplication {
          name = "pico-mon";
          runtimeInputs = [ pkgs.tio pkgs.coreutils ];
          text = ''
            set -euo pipefail
            dev="''${1:-}"
            if [ -z "$dev" ]; then
              # Pico の CDC-ACM を探す (Raspberry Pi のベンダID 2e8a)
              for d in /dev/serial/by-id/*Raspberry_Pi* /dev/ttyACM*; do
                [ -e "$d" ] && { dev="$d"; break; }
              done
            fi
            [ -n "$dev" ] || { echo "pico-mon: シリアルポートが見つからない。Pico にプログラムが書き込まれているか確認 (blink だけだと出てきません)" >&2; exit 1; }
            echo "接続: $dev  (終了: Ctrl-t q)"
            exec tio -b 115200 "$dev"
          '';
        };
      in
      pkgs.mkShell {
        packages = with pkgs; [
          gcc-arm-embedded # arm-none-eabi-gcc / arm-none-eabi-gdb (クロスコンパイラ)
          picotool # uf2 書き込み・デバイス情報
          cmake
          ninja
          python3 # SDK のビルドスクリプトが使う
          clang-tools # clangd (nvim の LSP)
          tio # シリアルモニタ
          openocd-rp2040 # Picoprobe 経由の SWD デバッグ用 (任意)
          pico-new
          pico-build
          pico-flash
          pico-mon
        ];

        # 拡張機能が ~/.pico-sdk に 2GB ダウンロードする代わりに、
        # nix store 上の SDK を指す (読み取り専用・世代管理される)。
        PICO_SDK_PATH = sdkPath;
        # 基板は Pico 1 (RP2040)。手順書の「Pico2 を選ぶと書き込めない」対策。
        PICO_BOARD = "pico";
        PICO_PLATFORM = "rp2040";

        shellHook = ''
          echo "Pico dev shell  (SDK: ${picoSdk.version}, $(arm-none-eabi-gcc -dumpversion) / arm-none-eabi)"
          echo "  pico-new <名前>  新規プロジェクト作成"
          echo "  pico-build       ビルド        (VsCode の Compile)"
          echo "  pico-flash       書き込み+実行 (VsCode の RUN)"
          echo "  pico-mon         シリアルモニタ"
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
