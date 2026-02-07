# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Gurkus der Schlaechter is a game built with Godot 4.5+.

## Development Commands

This project uses Nix flakes for environment management. Run `direnv allow` to automatically load the development environment, or use `nix develop` manually.

```bash
task editor        # Open Godot editor
task run           # Run the game
task precommit     # Run all pre-commit checks (parse + lint + format-check)
task check         # Run parse + lint
task lint          # Lint GDScript files
task format        # Auto-format GDScript files
task format-check  # Check formatting without modifying files
task validate      # Validate Godot project import
task parse         # Validate GDScript syntax only
```

## Architecture

### Scene/Script Organization
- **scenes/** - Godot scene files (.tscn)
- **scripts/** - GDScript logic, mirroring scene structure
- **assets/** - Audio, sprites, tilesets
- **resources/** - Godot resources (.tres)

## Code Style

GDScript files are linted and formatted using gdtoolkit. Run `task format` before committing to ensure consistent style.
