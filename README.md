# Steps to take


1. Generate an ssh key to link with your github.
```bash
ssh-keygen -t rsa -C "you@example.com"
```
2. Copy it into your github ssh key section as a new key


3. Clone the dotfiles
```bash
git clone git@github.com:EduardoNeville/dotfiles.git 
```

2. Run the install script by running
```bash
bash full_install 
```

3. Wezterm setup: 
```bash
Command + r 
```

## Nvim install

1. Go to configs/.config/nvim/lua/plugins.lua
2. Run :luafile %
3. Run :PackerInstall
4. Run :PackerCompile
5. Potential problems should be address individually

We need to install the fonts for the terminal this is done by either downloading the tff files with the local font downloader or installing it by had following the github instruction of the given font  
