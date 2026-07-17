{ pkgs ? import <nixpkgs> {
    config.allowUnfree = true;
  }
}:

pkgs.mkShell {
  packages = with pkgs; [
    ansible
    terraform
  ];

  shellHook = ''
    export HOST_HOME="$HOME"
    export HOME="$PWD/.home"

    mkdir -p "$HOME"
    ln -sfn "$HOST_HOME/.ssh" "$HOME/.ssh"
  '';
}
