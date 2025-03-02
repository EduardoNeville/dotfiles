# 🚀 Dotfiles Installation Script 🎉  

Welcome to your **dotfiles setup script!** This script is designed to automate the installation of essential development tools, symlink your personal configurations, and get your system ready for work. Whether you're setting up **MacOS** or **Linux**, this script has got your back. 💪  

---

## ✨ Features  

✅ **Installs package managers** (Homebrew for Mac, APT for Linux)  
✅ **Symlinks your dotfiles** to the appropriate locations  
✅ **Sets up ZSH** with your favorite plugins  
✅ **Installs Lazy.nvim** for managing Neovim plugins  
✅ **Runs Neovim to autoinstall all plugins via Lazy.nvim**  
✅ **Installs Rust & Cargo tools** as listed in `opt/cargoPkgs`  
✅ **Installs Pyenv** for Python version management  
✅ **Installs Docker** including the latest dependencies  
✅ **Fully interactive!** Choose what you want to install  

All in one go! 🏃💨  

---

## 🚦 Prerequisites  

Before running the script, ensure:  
- You have a **bash-compatible shell** installed (like `bash`, `zsh`).  
- You have **sudo privileges**, especially for installing system packages.  
- You have a **working internet connection** (we'll be downloading various tools).  
- You're running either **MacOS** or **Linux**.  

---

## 🛠 Installation Guide  

1. 🔽 **Clone your dotfiles repository**  
   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ```

2. 🎬 **Run the installation script**  
   ```bash
   bash full_install.sh
   ```

3. 🖱️ **Select what to install!** You'll see:  
   ```
   Select what to install:
   0) Package Manager
   1) Packages
   2) Dotfiles
   3) Zsh Plugins
   4) Lazy.nvim
   5) Neovim Plugins
   6) Rust
   7) Pyenv
   8) Docker
   Enter multiple numbers separated by spaces (e.g., 0 2 5):
   ```
   Simply enter a selection (**e.g., `0 1 6`**), and let the magic happen! 🎩  

---

## 🎉 What Happens After Installation?  

🔹 Your **Zsh configuration** (`.zshrc`), **Neovim setup**, and **dotfiles** will be symlinked correctly.  
🔹 Your **package manager** (APT or Homebrew) will be updated and packages installed.  
🔹 **Neovim Plugins** will be installed automatically by Lazy.nvim.  
🔹 **Rust and Cargo tools** will be set up based on **opt/cargoPkgs**.  
🔹 **Docker** will be installed and ready to go.  

When it's finished, your system will be **fully configured and ready for development!** 🚀  

---

## 🛠 Troubleshooting  

😕 **Something didn't install correctly?**  
- Ensure your package manager (`brew`, `apt`, etc.) is **working and up-to-date**.  
- If symlinking fails, check if existing files are blocking installation.  
- Verify your **internet connection** in case of download failures.  

🤖 **Need to rerun the installation?**  
- Simply run `bash full_install.sh` again and select what you need!  

---

## 📌 Customizations  

Want to **add more packages**?  
- Modify the `opt/` files:  
  - `opt/Brewfile` → for **Homebrew (Mac)** packages  
  - `opt/aptPkgs` → for **APT (Linux)** packages  
  - `opt/cargoPkgs` → for **Rust Cargo packages**  

Need to tweak configurations?  
- Modify `dotfiles/configs/` and the symlink process will ensure they apply.  

---

## 🏆 Why This Script?  

🔹 **Saves hours of setup time** by automating installations 🕒  
🔹 **Works for both MacOS & Linux** 🖥️🐧  
🔹 **Fully customizable** – add your own packages, tools, and configurations! ✏️  
🔹 **Your development environment, perfectly replicated across devices** 💾  

---

## 💪 Ready? Let’s Go! 🚀  

Run `bash full_install.sh`, grab some coffee ☕, and watch as your system configures itself! 🎉  

---

🎯 **Enjoy a fully set up development machine in minutes!** 🚀 Happy coding! 💻✨  
