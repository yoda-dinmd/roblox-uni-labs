# Roblox Labs

This repository contains a collection of game design labs and projects built using **Roblox Studio** and **Rojo**. It is structured as a monorepo to keep all assignments organized and version-controlled.

## 📁 Repository Structure

Each lab is contained within its own directory to ensure isolation of scripts and configurations:

* `lab-N-name/`: The root directory for a specific assignment.
* `lab-N-name/default.project.json`: The Rojo configuration file.
* `lab-N-name/src/`: Contains the actual Lua source code.

---

## 🛠 Workflow: Porting a New Lab

When receiving a new `.rbxl` file from the instructor, follow these steps to port it into the repository:

1. **Initialize the Folder**: Create a new folder following the naming convention: `lab-N-nameoflab`.
2. **Convert the Place**: Use the `rbxlx-to-rojo` tool to port the existing game file into a Rojo-compatible structure. Refer to the [Rojo Existing Game Documentation](https://rojo.space/docs/v7/getting-started/existing-game/) for detailed conversion steps.
3. **Add to Git**: Ensure the new folder and its `src` directory are tracked by Git.

---

## 🚀 How to Work on a Lab

To start development and sync your code with Roblox Studio:

1. **Open the Project**: Open the specific lab folder (e.g., `lab-N-nameoflab`) in **VS Code**.
2. **Start the Rojo Server**:
* Press `Ctrl + Shift + P` to open the Command Palette.
* Type `Rojo: Show Menu` and select it.
* Click on your `default.project.json` to start the live-syncing server.
* For more details on the sync process, see the [Rojo Getting Started Guide](https://rojo.space/docs/v7/getting-started/new-game/).


3. **Connect in Studio**:
* Open the corresponding `.rbxl` file in Roblox Studio.
* Click **Connect** to begin the live-sync session.

---

## 📜 Contribution & Standards

To maintain a clean commit history and organized branching, all work must follow the rules defined in the [CONTRIBUTING.md](https://www.google.com/search?q=./CONTRIBUTING.md) file.