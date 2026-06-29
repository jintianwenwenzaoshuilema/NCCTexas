# NCCTexas

NCCTexas is a Godot 4 Texas Hold'em project. It includes a poker core, a playable test table scene, and regression tests for the game logic.

## Requirements

- Godot 4.7 or newer in the Godot 4 series.
- Git.
- Optional: Codex, ChatGPT, Cursor, Claude Code, or another AI coding tool for assisted development.

This project uses GDScript and does not require the Godot .NET/C# build.

## Download Godot

Use the official Godot download page:

- All platforms: https://godotengine.org/download/
- Windows: https://godotengine.org/download/windows/
- macOS: https://godotengine.org/download/macos/
- Linux: https://godotengine.org/download/linux/
- Android editor: https://godotengine.org/download/android/
- Web editor: https://editor.godotengine.org/

Recommended choices:

- Windows: download the standard Godot Engine 4.x `x86_64` build, unzip it, and run the executable.
- macOS: download the standard Godot Engine 4.x build for your Mac, open the app, and allow it in System Settings if macOS blocks the first launch.
- Linux: download the standard Godot Engine 4.x build, extract it, make the binary executable if needed, and run it.

Godot is self-contained, so there is usually no separate installer. The .NET/C# build is only needed for C# projects; NCCTexas does not need it.

## Get the Project

Clone the repository:

```sh
git clone https://github.com/jintianwenwenzaoshuilema/NCCTexas.git
cd NCCTexas
```

Or, if you already have the project locally:

```sh
cd /Users/zlw/NCCTexas
git pull
```

## Open and Run

1. Open Godot.
2. Click `Import`.
3. Select this project's `project.godot` file.
4. Open the imported project.
5. Press `F5` or click the play button.

The main scene is configured in `project.godot`, so Godot should start the poker test table directly.

You can also run from the command line:

```sh
godot --path .
```

If your Godot binary has a versioned name, use that command instead, for example:

```sh
godot4 --path .
```

## Run Tests

Run the poker core tests:

```sh
godot --headless --path . -s res://tests/poker_core_tests.gd
```

Run the UI smoke test:

```sh
godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
```

If your executable is named `godot4`, replace `godot` with `godot4`.

## Project Layout

- `project.godot`: Godot project configuration.
- `scenes/poker_test.tscn`: Main test table scene.
- `scenes/poker_test.gd`: Table UI and game interaction script.
- `scenes/ui/card_view.tscn`: Card view scene.
- `scenes/ui/card_view.gd`: Self-drawn card front, back, and empty-slot rendering.
- `poker/`: Texas Hold'em core logic.
- `tests/`: Headless regression and smoke tests.

## Development Workflow

Before making changes:

```sh
git status
git pull
```

After making changes:

```sh
godot --headless --path . -s res://tests/poker_core_tests.gd
godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
git status
git add .
git commit -m "Describe the change"
git push
```

Use focused commits. For example, keep visual card changes separate from poker rules changes when possible.

## Developing with Codex or Other AI Tools

AI tools work best when you give them the repository path, the current goal, and the verification command.

Example prompt:

```text
We are working on the Godot 4 project at /Users/zlw/NCCTexas.
Please inspect the project before editing. Implement [feature or bug fix].
Afterward run:
godot --headless --path . -s res://tests/poker_core_tests.gd
godot --headless --path . -s res://tests/poker_ui_smoke_test.gd
Do not overwrite unrelated local changes.
```

Good tasks for AI assistance:

- Refactor small parts of `poker/` while preserving test behavior.
- Add focused tests for a specific poker rule.
- Adjust UI layout in `scenes/poker_test.gd`.
- Improve card rendering in `scenes/ui/card_view.gd`.
- Update documentation after a feature lands.

Be careful with AI-generated changes:

- Review `git diff` before committing.
- Run the headless tests after logic changes.
- Open the project in Godot after scene or UI changes.
- Avoid broad rewrites unless the current behavior is well covered by tests.
- Keep generated code consistent with the existing GDScript style.

## GitHub Authentication

For pushing changes over HTTPS, configure Git and authenticate with GitHub:

```sh
git config --global user.name "Your GitHub username"
git config --global user.email "your-email@example.com"
git config --global credential.helper osxkeychain
```

Then push:

```sh
git push
```

When GitHub asks for a password, use a GitHub personal access token instead of your GitHub account password.

SSH authentication also works, but it is optional.
