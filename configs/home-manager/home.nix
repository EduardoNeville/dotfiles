{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "eduardoneville";
    home.homeDirectory = "/home/eduardoneville";

    # target linux
    targets.genericLinux.enable = true;

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "23.11"; # Please read the comment before changing.

    # The home.packages option allows you to install Nix packages into your
    # environment.
    home.packages = [
        # ----
        # Terminal & Shell
        # ----
        pkgs.wezterm
        pkgs.starship
        pkgs.zsh

        # ---
        # Text Editors
        # ---
        pkgs.vim
        pkgs.neovim

        # ---
        # CLI utils
        # ---
        pkgs.fd
        pkgs.fzf
        pkgs.bat
        pkgs.eza
        pkgs.ripgrep
        pkgs.diff-so-fancy
        pkgs.nnn
        pkgs.curl
        pkgs.zoxide

        # ---
        # System Info & Display
        pkgs.neofetch
        pkgs.btop
    
        # ---
        # Syntax & fonts
        # ---
        pkgs.tree-sitter
        pkgs.fira-code
        pkgs.fira-code-nerdfont
        
        # ---
        # Langs & Frameworks
        # ---
        pkgs.nodejs
        pkgs.gcc
        pkgs.gdb
        pkgs.git
        pkgs.pyenv
        pkgs.openssh

        # ---
        # Applications
        # ---
        pkgs.telegram-desktop

    ];

    # Home Manager is pretty good at managing dotfiles. The primary way to manage
    # plain files is through 'home.file'.
    home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
    };

    # Home Manager can also manage your environment variables through
    # 'home.sessionVariables'. If you don't want to manage your shell through Home
    # Manager then you have to manually source 'hm-session-vars.sh' located at
    # either
    #
    #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
    #
    # or
    #
    #  /etc/profiles/per-user/eduardoneville/etc/profile.d/hm-session-vars.sh
    #
    home.sessionVariables = {
    EDITOR = "nvim";
    };

    # Let Home Manager install and manage itself.
    programs.home-manager.enable = true;

    # wayland setup
    wayland.windowManager.hyperland.enable = true;
}
