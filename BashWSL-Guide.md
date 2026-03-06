# 🐧 The Ultimate WSL (Ubuntu) Command Guide
### *For David & the Power User Community*

Welcome to the command line! This guide covers essential commands for navigating Ubuntu within the Windows Subsystem for Linux (WSL).

---

## 📂 1. Navigation & Exploration
*Moving around the file system is the first skill to master.*

| Command | Description | Example |
| :--- | :--- | :--- |
| **`pwd`** | **P**rint **W**orking **D**irectory. Shows exactly where you are. | `pwd` |
| **`ls`** | **L**i**s**t files in the current directory. | `ls` |
| **`ls -la`** | List **all** files (including hidden) with details/sizes. | `ls -la` |
| **`cd <dir>`** | **C**hange **D**irectory to a specific folder. | `cd my_folder` |
| **`cd ..`** | Go **up** one directory level. | `cd ..` |
| **`cd ~`** | Go to your **home** directory (`/home/david`). | `cd ~` |
| **`cd -`** | Go back to the **previous** directory (Toggle back/forth). | `cd -` |

---

## 📝 2. File & Folder Operations
*Creating, moving, and safely destroying things.*

### Creating & Copying
```bash
# Create an empty file
touch filename.txt

# Create a directory (folder)
mkdir new_folder

# Create nested directories (e.g., projects/web/site)
mkdir -p projects/web/site

# Copy a file
cp source.txt destination.txt

# Copy a folder and everything inside it (Recursive)
cp -r source_folder/ destination_folder/

Moving & DeletingBash# Move a file (also used to Rename)
mv old_name.txt new_name.txt

# Remove a file
rm file.txt

# Remove a folder and everything inside it (Force/Recursive)
# ⚠️ WARNING: This bypasses the Recycle Bin and cannot be undone.
rm -rf folder_name/
👁️ 3. Viewing & Editing FilesFor when you need to tweak a Python script or check a log.CommandDescriptioncat <file>Dumps the whole file content to the terminal.less <file>View file page-by-page. Press q to quit.head -n 5View the first 5 lines of a file.tail -fView the end of a file and follow updates (Live logs).nano <file>Simple terminal text editor. (Ctrl+O Save, Ctrl+X Exit).code .WSL Magic: Opens the current folder in VS Code on Windows.🪟 4. WSL Specifics (Windows Interop)The bridge between Linux and your Windows files.Tip: Your Windows drives are mounted under /mnt/.Access C: Drive: cd /mnt/c/Users/david/DesktopOpen Windows Explorer here: explorer.exe .Copy Linux output to Windows Clipboard: cat file.txt | clip.exe🛠️ 5. Package Management (Advanced Power)Installing the tools you need.Update your package list first: sudo apt updateUpgrade installed packages: sudo apt upgradeInstall a new tool (e.g., htop): sudo apt install htopRemove a tool: sudo apt remove python3🔐 6. Permissions & OwnershipWho is allowed to do what?chmod (Change Mode): Changes read/write/execute permissions.Bash# Make a script executable (essential for .sh files)
chmod +x script.sh

# Give full permissions to owner, read/execute to others
chmod 755 file.txt
chown (Change Owner): Changes who owns the file.Bash# Change owner to 'david'
sudo chown david file.txt
🚀 7. Productivity Tricks (Moderate Level)Leveling up your workflow.Pipes and Redirection| (Pipe): Takes output of the left and feeds it to the right.> (Redirect): Saves output to a file (overwrites).>> (Append): Adds output to the end of a file.Bash# Search for "error" in a log and save it to a new file
cat app.log | grep "error" > errors.txt

# List running processes and scroll through them
ps aux | htop
Grep (Search)Bash# Search for a string inside a file
grep "search_term" filename.txt

# Search recursively (case insensitive) inside a folder
grep -ri "function_name" ./src/
Historyhistory: See everything you've typed.!!: Execute the last command again (useful if you forgot sudo).Ctrl + R: Search your history. Just start typing a command you used before.🛡️ 8. System MonitoringCommandDescriptionhtopShows real-time CPU and RAM usage (Task Manager for Linux).df -hShows disk space usage in human-readable (GB/MB) format.free -hShows how much RAM is currently being used by WSL.pkill <name>Stop a process by name (e.g., pkill node).🌟 9. Beginner-Moderate AdditionsThings you'll actually use.Creating Shortcuts (Aliases)Tired of typing long paths to your Windows Projects? Add an alias.Bash# Open your config
nano ~/.bashrc

# Add this to the bottom
alias docs="cd /mnt/c/Users/david/Documents"

# Save and reload
source ~/.bashrc
Handling Archives (Zip/Unzip)Bash# Zip a folder
zip -r my_backup.zip folder_name/

# Unzip a folder
unzip my_data.zip
Need Help?Almost every command has a manual. Type man <command> (e.g., man ls). Press q to exit.
