### 🚀 System Initialization Checklist

Follow these steps when deploying this **MasterPlan** on a new machine or after a fresh OS install:

* **1. Install Dotfiles (Zsh + Oh My Zsh + P10k)**:
    ```bash
    git clone https://github.com/DavidBoehm/MasterPlan.git ~/MasterPlan
    cd ~/MasterPlan/dotfiles
    chmod +x bootstrap.sh
    ./bootstrap.sh
    zsh
    ```
    See [Dotfiles README](dotfiles/README.md) for full details.

* **2. Elevate Permissions**: Ensure the interactive toolkits are runnable in your terminal.
    ```bash
    chmod +x gh_kit.sh ollama_kit.sh
    ```

* **3. Initialize Submodules**: Pull in your centralized configuration and security tools defined in your `.gitmodules`.
    ```bash
    git submodule update --init --recursive
    ```

* **4. Windows Optimization (If on Host)**: Run the scripts in `RegEdit.md` to restore the classic context menu, disable Bing search, and unlock USB power settings for 3D printing.

* **5. Hardware Audit**: If you are at the office or troubleshooting smart locks, verify signal strength and WPA handshakes using the `airodump-ng.md` guide.

* **6. Security Baseline**:
    * Verify you are using **SSH Keys** (Ed25519) instead of passwords.
    * Ensure your user has `sudo` privileges but never log in directly as `root`.

* **7. Environment Paths**: Add this repository to your `$PATH` in your `~/.bashrc` or `~/.zshrc` to call these scripts from any directory.
    ```bash
    export PATH=$PATH:$(pwd)
    ```

# 📂 MasterPlan: The Command Center

A centralized compilation of scripts, automation toolkits, and system configurations tailored for a hybrid environment across **Unraid**, **Windows 11 (WSL2)**, and **Kali Linux**.

## 🛠️ Integrated Toolkits

### 🛡️ Windows Administration
* **[NetKit & Toolkits](windows/netkit.ps1)**: Menu-driven PowerShell frameworks for network diagnostics, DNS flushing, and WSL management.
* **[Registry Tweaks](RegEdit.md)**: Performance optimizations, including context menu restoration and USB power management for 3D printing.

### 💻 Developer & AI Workflow
* **[GitHub CLI Toolkit (gh_kit.sh)](gh_kit.sh)**: OS-aware automation for repository management and rapid commits.
* **[Ollama Master Toolkit (ollama_kit.sh)](ollama_kit.sh)**: Interactive management of local LLMs and server configurations.
* **[Node.js & NPM Guide](Node-ect.md)**: Essential command reference for JavaScript runtime management.

### 🐧 Linux & Security
* **[WSL Ubuntu Guide](BashWSL-Guide.md)**: Navigation and productivity "magic" for the Windows Subsystem for Linux.
* **[Wireless Diagnostics](airodump-ng.md)**: Troubleshooting guide for IoT connectivity using `airodump-ng`.
* **[Best Practices](BestPractices.md)**: Deep-dive into Linux hierarchy, security, and symlink logic.

## 🏗️ System Architecture

This repository uses **Git Submodules** to maintain environmental consistency across machines:
* **[Dotfiles](https://github.com/DavidBoehm/dotfiles.git)**: Centralized Zsh/p10k and tool configurations.
* **[Kali Scripts](https://github.com/DavidBoehm/kali_scripts.git)**: Specialized security auditing tools.

## 💾 Unraid Server Management
* **[Unraid Reference](unraid/readme.md)**: Emergency recovery keys (REISUB), performance tuning, and Docker optimization strategies.
* **[Structure Map](unraid_structure_export.txt)**: A visual reference of the server's share and directory hierarchy.