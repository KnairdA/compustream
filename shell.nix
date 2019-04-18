{ pkgs ? import <nixpkgs> { }, ... }:

pkgs.stdenvNoCC.mkDerivation rec {
  name = "compustream-env";
  env = pkgs.buildEnv { name = name; paths = buildInputs; };

  buildInputs = with pkgs; [
    cmake
    universal-ctags
    gcc8
    gdb cgdb
    glfw3
    glew
    glm
  ];

  shellHook = ''
    export NIX_SHELL_NAME="${name}"
  '';
}
