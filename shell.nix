with import <nixpkgs> {};

stdenvNoCC.mkDerivation rec {
  name = "compustream-env";
  env = buildEnv { name = name; paths = buildInputs; };

  buildInputs = [
    fish
    git cmake
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
