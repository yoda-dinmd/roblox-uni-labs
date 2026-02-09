# Contributing to Roblox Uni Labs

This document defines the branching strategy and naming conventions for managing university lab assignments. Following these rules ensures the repository remains organized as a portfolio-ready monorepo.

## 1. Branching Workflow

We use a feature-branch workflow. Since this is a collection of labs, each new lab or major fix should be developed in its own branch.

* **`main`**: The stable branch. This should only contain completed, tested labs that are ready for submission.
* **`develop`**: The integration branch where active lab work happens before being finalized.

**Standard Workflow:**

1. **Sync Local Environment:**
```bash
git checkout develop
git pull origin develop

```


2. **Create a Lab Branch:**
```bash
git checkout -b lab/name-of-assignment

```


3. **Work and Commit:** Use Rojo to sync your scripts and commit frequently.
4. **Finalize:** Once the lab is complete, push to GitHub and create a **Pull Request (PR)** to merge into `develop`.

## 2. Naming Conventions

### Branch Names

Use the format `category/description`.

* `lab/dj-loop-station` (e.g., for your Multimedia assignment)
* `fix/camera-script-bug`
* `refactor/optimize-datastore`

### Commit Messages

We follow **Conventional Commits** to keep the history readable: `type(lab-name): description`.

* **`feat`**: A new mechanic or script for a lab.
* **`fix`**: A bug fix in a script.
* **`chore`**: Updating Rojo configurations or `.gitignore`.
* **`docs`**: Writing READMEs for specific labs.

**Examples:**

* `feat(lab3): implement track switching logic for DJ station`
* `fix(shared): resolve remote event latency in networking module`
* `chore: update default.project.json to include new folders`

## 3. Pull Request (PR) Format

When merging a lab into `develop` or `main`, use the following title format:
`[LAB #] Title of the Assignment`