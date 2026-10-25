# BLACKTAIL: ALLEY RUN

A 2D side-scrolling rooftop endless runner for Android: a black cat with amber eyes
racing across hand-drawn South Asian rooftops. Built with Godot 4 + GDScript.

> **Status: playable vertical slice.** The previous web game ("RENT IS DUE") is
> preserved on the `legacy/rent-is-due` branch.

## How to play
- The cat runs automatically from left to right.
- **Jump:** tap the left side of the screen or the cat button. Hold for a higher jump.
- **Slide:** swipe down or press the arrow button (slide under hanging rugs).
- Collect fish; jump rooftop gaps, water tanks and crates. Three hearts; falling = game over.
- Keyboard: ↑/W/Space jump, ↓/S slide, P pause, Enter restart.

## Get the APK from your phone
1. **Actions** tab → **Build Blacktail Android APK** → **Run workflow** (choose the branch).
2. When the run is green, download `blacktail-alley-run-debug-apk`, unzip, install.

## Art direction
`docs/art-reference.png` is the visual target (reference only, not shipped).
All in-game art is drawn procedurally in code in a comic style — wobbly ink outlines,
cracked plaster, exposed brick, water tanks, AC units, rugs, wires and layered parallax
city (`scripts/ink.gd`, `rooftop.gd`, `backdrop.gd`). Painted PNG layers can replace a
`Backdrop` kind or `Rooftop` facade later without touching gameplay.

The cat is the CC0 Quaternius model animated procedurally (`scripts/cat_rig.gd`) and
rendered live into the 2D scene from a side camera (`scripts/cat_view.gd`).

## Project layout
```
scenes/main.tscn   entry scene
scripts/game.gd    runner physics, level generation, input, HUD wiring, autopilot test
scripts/rooftop.gd runnable building + obstacles     scripts/backdrop.gd  parallax layers
scripts/ink.gd     hand-drawn drawing helpers        scripts/hud.gd       HUD
scripts/fish.gd    collectible                        scripts/cat_view.gd / cat_rig.gd  cat
assets/cat/        Cat.fbx (CC0, Quaternius) + CREDITS.md
tools/capture.sh   renders a gameplay video locally (not exported)
```

## Local commands (Godot 4.7.2)
```bash
godot --headless --import
godot --headless -- --test=30   # autopilot run + forced death + restart; prints TEST_RESULT
godot -- --demo                 # watch the autopilot
```

## Credits
Cat model: "Animal Pack Vol.2" by Quaternius, CC0 — see `assets/cat/CREDITS.md`.
