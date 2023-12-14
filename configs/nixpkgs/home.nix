{ pkgs, ...}: {
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      . ~/oldbashrc
    '';
  };

  home.packages = [
        pkgs.nnn,
        pkgs.bat,
        pkgs.vim,
        pkgs.fd,
        pkgs.tree-sitter,
        pkgs.fzf,
        pkgs.bat,
        pkgs.exa,
        pkgs.ripgrep,
        pkgs.diff-so-fancy,
        pkgs.btop,
        pkgs.zsh,
        pkgs.neofetch,
        pkgs.curl,
        pkgs.fd-find,
        pkgs.zoxide,
        pkgs.nodejs,
        pkgs.npm,
        pkgs.openssh-server ,
        pkgs.gcc,
        pkgs.g++,
        pkgs.gdb,
        pkgs.git,
  ];
}
