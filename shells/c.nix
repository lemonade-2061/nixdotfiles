# C/C++学習用 devShell (競プロ・自作malloc等): nix develop ~/nixos#c
#
# flake.nix から { pkgs }: で呼ばれる。
{ pkgs }:

pkgs.mkShell {
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
}
