{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "eduardoneville";
    home.homeDirectory = "/home/eduardoneville";

    #xdg.enable = true;
    #xdg.mime.enable = true;

    # target linux
    targets.genericLinux.enable = true;

    # Dwm setup
    services.xserver.windowManager.dwm.enable = true;
    services.xserver.windowManager.dwm.package = pkgs.dwm.overrideAttrs {
        src = ./../suckless/dwm-6.2/dwm;
    }


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
        # Minimal install
        # ----
        pkgs.bash           # shell
        pkgs.zsh            # shell
        pkgs.starship       # prompt
        pkgs.git            # version control
        pkgs.gh             # github cli
        pkgs.vim            # text editor
        pkgs.neovim         # text editor
        pkgs.fd             # find replacement
        pkgs.fzf            # fuzzy finder
        pkgs.bat            # cat replacement
        pkgs.eza            # ls replacement
        pkgs.ripgrep        # grep replacement
        pkgs.nnn            # file manager
        pkgs.curl           # http client
        pkgs.zoxide         # cd replacement
        pkgs.delta          # diff viewer
        pkgs.neofetch      # system info
        pkgs.btop          # system monitor

        # ----
        # Terminal
        # ----
        pkgs.wezterm       # terminal

        # ---
        # CLI utils
        # ---
        pkgs.gdb            # debugger
        pkgs.zathura        # pdf viewer
        pkgs.sioyek         # pdf viewer
        pkgs.lazygit        # git gui

        # ---
        # Syntax & fonts
        # ---
        pkgs.tree-sitter   # syntax highlight
        pkgs.fira-code
        pkgs.nerdfonts
        pkgs.fira-code-nerdfont
        
        # ---
        # Langs & Frameworks
        # ---
        pkgs.nodejs
        pkgs.gcc
        pkgs.pyenv
        pkgs.openssh

        # ---
        # Applications
        # ---
        pkgs.telegram-desktop
        pkgs.discord
        pkgs.firefox

        # ---
        # WM Features
        # ---
        pkgs.dwm
        pkgs.dunst
        pkgs.rofi

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
        pkgs.ncspot        # spotify cli

    # wayland setup
    #wayland.windowManager.hyperland.enable = true;

    #wayland.windowManager.hyprland.settings = {
    #    "$mod" = "SUPER";
    #    bind =
    #      [
    #        "$mod, F, exec, firefox"
    #        ", Print, exec, grimblast copy area"
    #      ]
    #      ++ (
    #        # workspaces
    #        # binds $mod + [shift +] {1..10} to [move to] workspace {1..10}
    #        builtins.concatLists (builtins.genList (
    #            x: let
    #              ws = let
    #                c = (x + 1) / 10;
    #              in
    #                builtins.toString (x + 1 - (c * 10));
    #            in [
    #              "$mod, ${ws}, workspace, ${toString (x + 1)}"
    #              "$mod SHIFT, ${ws}, movetoworkspace, ${toString (x + 1)}"
    #            ]
    #          )
    #          10)
    #      );
    #};
}
