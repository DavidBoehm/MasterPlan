To understand the difference between **git** and **gh**, it helps to think of them as the **Engine** vs. the **Remote Control**.

### 1. Git: The Engine (Local)
**Git** is the core version control system that lives on your computer. It is the "engine" that tracks every change you make to your files in the `MasterPlan` repo.
* **What it does:** It creates "snapshots" (commits) of your work so you can go back in time if you break something.
* **Where it works:** It works entirely offline on your HP Envy or main PC.
* **Common Commands:** `git add`, `git commit`, `git branch`.



### 2. GH: The Remote Control (GitHub CLI)
**gh** is the "GitHub CLI." It is a tool created by GitHub to let you manage your **online** account and repositories directly from your terminal.
* **What it does:** It handles things that happen *outside* of your local code, like creating a repository on the website, managing "Pull Requests," or checking "Issues".
* **Where it works:** It requires an internet connection and an active login to your GitHub account.
* **Common Commands:** `gh auth login`, `gh repo create`, `gh pr create`.



### Summary Comparison

| Feature | Git | gh (GitHub CLI) |
| :--- | :--- | :--- |
| **Focus** | **Files & History:** Tracking what changed in your code. | **GitHub Platforms:** Managing your account, PRs, and online repos. |
| **Internet** | Not required for local commits. | Required to talk to GitHub servers. |
| **Scope** | Works with any Git server (GitLab, Bitbucket, Unraid). | Specifically designed for **GitHub.com**. |
| **Your Usage** | Used in `git_kit.sh` for daily coding saves. | Used in `gh_kit.sh` to clone repos and manage PRs. |

### How they work together in your MasterPlan
In your unified solution, you use **Git** to save your work locally on your Kali machine. Once you are ready to share that work, you use **gh** to tell GitHub to "Open a Pull Request" so you can merge your changes into the main MasterPlan repo.