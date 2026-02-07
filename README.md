# Gurkus der Schlaechter

A Godot 4 game project.

## Requirements

- [Nix](https://nixos.org/) with flakes enabled
- Or manually install: Godot 4.5+, go-task, gdtoolkit

## Getting Started

```bash
# Enter development environment
direnv allow

# Or manually with nix
nix develop

# Open in Godot editor
task editor

# Run the game
task run
```

## Available Commands

| Command | Description |
|---------|-------------|
| `task run` | Run the game |
| `task editor` | Open Godot editor |
| `task precommit` | Pre-commit checks (parse + lint + format-check) |
| `task check` | Run all checks (parse + lint) |
| `task lint` | Lint GDScript files |
| `task format` | Auto-format GDScript |
| `task validate` | Validate Godot project |

## Project Structure

- `scenes/` - Godot scene files (.tscn)
- `scripts/` - GDScript files (.gd)
- `assets/` - Sprites, audio, etc.
- `resources/` - Godot resources (.tres)
