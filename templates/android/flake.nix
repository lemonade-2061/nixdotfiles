{
    inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    outputs = { nixpkgs, ... }:
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          config.android_sdk.accept_license = true;
        };

        # プロジェクトの compileSdk と AGP の既定 build-tools に合わせる。
        # SDK は read-only の store にあるので、足りないと AGP が自動 DL できずに落ちる。
        platformVersion = "36";
        buildToolsVersions = [ "35.0.0" "36.0.0" ];

        sdk = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ platformVersion ];
          inherit buildToolsVersions;
          # エミュレーターも使うなら true にする (数 GB 増える)
          includeEmulator = false;
          includeSystemImages = false;
          # systemImageTypes = [ "google_apis_playstore" ];
          # abiVersions = [ "x86_64" ];
        };

        sdkRoot = "${sdk.androidsdk}/libexec/android-sdk";
        jdk = pkgs.jdk21; # Gradle 8.x は jdk25 だと動かない
      in {
        devShells.${system}.default = pkgs.mkShell {
          packages = [ sdk.androidsdk pkgs.android-tools jdk ];

          ANDROID_HOME = sdkRoot;
          ANDROID_SDK_ROOT = sdkRoot;
          JAVA_HOME = "${jdk}";
          # Maven から落ちてくる aapt2 は NixOS で動かないので、androidenv の物を使わせる
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdkRoot}/build-tools/${pkgs.lib.last buildToolsVersions}/aapt2";
        };
      };
  }
