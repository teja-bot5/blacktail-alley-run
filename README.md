# BLACKTAIL: ALLEY RUN

A 2D side-scrolling rooftop endless runner for Android: a black cat with amber eyes
racing across hand-drawn South Asian rooftops. Built with Godot 4 + GDScript.

> **Status: playable vertical slice.** The previous web game ("RENT IS DUE") is
> preserved on the `legacy/rent-is-due` branch.

## How to play
- Press **PLAY**: the cat stands up from its rooftop perch and starts running.
- **Jump:** tap anywhere (or the cat button). Every jump has the same arc.
- **Slide:** swipe down or press the arrow button.
- Jump: crates, broken walls, water tanks, AC units, rooftop gaps.
  Slide: hanging rugs and low cable bundles with shop signs.
- Three hearts; falling into a gap or running into a wall = game over.
- **SOUND** button (home/pause/game-over screens): on → low → off.
- Keyboard: ↑/W/Space jump, ↓/S slide, P pause, Enter play/restart.

## Get the APK from your phone
1. **Actions** tab → **Build Blacktail Android APK** → **Run workflow** (choose the branch).
2. When the run is green, download `blacktail-alley-run-debug-apk`, unzip, install.

## Art direction
`docs/art-reference.png` is the visual target (reference only, not shipped).
All in-game art is drawn procedurally in code in a comic style — wobbly ink outlines,
cracked plaster, exposed brick, water tanks, AC units, rugs, wires and layered parallax
city (`scripts/ink.gd`, `rooftop.gd`, `backdrop.gd`). Painted PNG layers can replace a
`Backdrop` kind or `Rooftop` facade later without touching gameplay.

The cat (`scripts/cat2d.gd`) is a procedurally drawn and animated 2D silhouette:
planted-foot gallop, jump phases, slide and a sitting idle. All audio is
synthesised at startup (`scripts/sfx.gd`) — no audio files.
`cat_rig.gd`, `cat_view.gd`, `pal.gd` and `assets/cat/` are the earlier 3D cat, now unused.

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
tools/run_tests.sh              # every obstacle (jump/slide/none) at 2 speeds, gaps,
                                # touch input (needs xvfb-run), endurance + restart
godot -- --demo                 # watch the autopilot
```

## Credits
Cat model: "Animal Pack Vol.2" by Quaternius, CC0 — see `assets/cat/CREDITS.md`.
