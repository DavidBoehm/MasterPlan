# 🟢 Node.js, NPM & NVM: The Essential Command List

This guide covers the top 20 commands for managing your JavaScript runtime and dependencies.

---

## 📦 1. NVM (Node Version Manager)

*Use these to manage your Node.js installation versions.*

| Command | Description |
| :--- | :--- |
| `nvm install --lts` | Installs the latest **Long Term Support** version of Node (Recommended for stability). |
| `nvm install <version>` | Installs a specific version (e.g., `nvm install 18`). |
| `nvm use <version>` | Switches the active Node version for the **current** terminal session. |
| `nvm alias default <version>` | Sets the default Node version to use whenever you open a **new** terminal. |
| `nvm list` | Lists all Node versions currently installed on your machine. |

## ⚡ 2. Node.js (Runtime)

*Basic execution commands.*

| Command | Description |
| :--- | :--- |
| `node -v` | Checks the currently active Node.js version. |
| `node <filename.js>` | Executes a JavaScript file (e.g., `node server.js`). |
| `node` | Enters the **REPL** (Read-Eval-Print Loop) to type and execute JS code interactively. |

## 🏗️ 3. NPM (Project Setup & Dependencies)

*Managing packages and `package.json`.*

| Command | Description |
| :--- | :--- |
| `npm init -y` | Generates a `package.json` file with default settings (skips the questionnaire). |
| `npm install` | Installs all dependencies listed in your `package.json` (creates `node_modules`). |
| `npm install <package>` | Installs a package and adds it to `dependencies` (e.g., `npm install express`). |
| `npm install -D <package>` | Installs a package as a **Dev Dependency** (e.g., `npm install -D nodemon`). |
| `npm install -g <package>` | Installs a package **globally** on your system (e.g., `npm install -g typescript`). |
| `npm uninstall <package>` | Removes a package from `node_modules` and `package.json`. |
| `npm ci` | **Clean Install**. Deletes `node_modules` and installs exact versions from `package-lock.json`. Essential for CI/CD. |

## 🛠️ 4. NPM (Scripts & Maintenance)

*Running tasks and keeping things clean.*

| Command | Description |
| :--- | :--- |
| `npm run <script>` | Runs a custom script defined in the `"scripts"` section of `package.json`. |
| `npm start` | Shortcut for `npm run start`. Often used to start servers. |
| `npm test` | Shortcut for `npm run test`. Used to run test suites (Jest, Mocha, etc.). |
| `npm outdated` | Checks the registry to see if any of your installed packages have newer versions. |
| `npm audit fix` | Scans your project for security vulnerabilities and automatically attempts to fix compatible ones. |
