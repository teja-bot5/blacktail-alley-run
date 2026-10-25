# BLACKTAIL — Alley Run

An offline 2D side-scrolling endless runner for Android. You are a black cat with
amber eyes, racing left to right across hand-drawn Indian rooftops: leap the gaps
between buildings, clear rooftop clutter, slide under hanging rugs and cables, and
collect fish. Built with Godot 4 and GDScript.

Maintained by [teja-bot5](https://github.com/teja-bot5).

## Features
- Procedurally drawn and animated cat: planted-foot gallop, crouch–takeoff–tuck–landing
  jumps, belly slide, and a sitting idle on the home screen.
- Comic-style city drawn entirely in code: ink outlines, cracked plaster, exposed brick,
  water tanks, AC units, rugs, wires with birds and layered parallax backgrounds.
- Obstacles with one clear answer each — **jump:** crates, broken walls, water tanks,
  AC units and rooftop gaps; **slide:** hanging rugs and low cable bundles with signs.
- Fair, endless generation: speed and obstacle variety ramp up gradually, and nothing
  is placed where the cat lands after a gap.
- Three hearts, fish counter, score, saved best score, instant restart.
- Synthesised sound effects, ambience and music (no audio files), with an on/low/off control.
- Works fully offline.

## Controls
**Touch**
- **PLAY** on the home screen starts the run.
- **Jump:** tap anywhere, or press the cat button (bottom right). Every jump has the same arc.
- **Slide:** swipe down, or press the arrow button (bottom right).
- **Pause:** the pause button (top right).
- **SOUND** (home, pause and game-over screens) cycles on → low → off.

**Keyboard** (desktop)
- ↑ / W / Space: jump (also starts or restarts a run)
- ↓ / S: slide
- P / Esc: pause / resume
- Enter: play, resume or restart

## Get the Android build
The GitHub Actions workflow **Build Blacktail Android APK** (`.github/workflows/android-apk.yml`)
runs the automated tests and exports a debug APK. It runs on pushes to `main` and can be
started manually:

1. Open the repository's **Actions** tab → **Build Blacktail Android APK** → **Run workflow**
   and choose a branch.
2. When the run finishes successfully, download the **`blacktail-alley-run-debug-apk`**
   artifact (you must be signed in to GitHub).
3. Unzip it and open `blacktail-alley-run-debug.apk` on your Android device. You may need
   to allow installing apps from your browser or file manager.

This is a debug build signed with a throwaway key, intended for testing — not a Play Store release.

## Developer setup
Requirements: [Godot 4.7.2](https://godotengine.org/download/) (standard build).
`xvfb-run` is needed for the touch-input test; `xvfb-run` and `ffmpeg` for `tools/capture.sh`.

```bash
godot --headless --import                  # import assets once
godot                                      # run the game (scenes/main.tscn)
godot -- --demo                            # watch the autopilot play
GODOT=/path/to/godot tools/run_tests.sh    # all automated tests
```

`tools/run_tests.sh` runs every obstacle type with and without the correct action at
two speeds, rooftop gaps, a touch-input test (PLAY, tap, swipe, on-screen buttons) and an
endurance run that ends in game over and restart. It prints `ALL TESTS PASS` on success.

**Android export.** The workflow shows the full, working setup: Java 17, Android SDK
(`platform-tools`, `build-tools;34.0.0`, `platforms;android-34`), Godot 4.7.2 Android
export templates and a debug keystore configured in Godot's editor settings. Then:

```bash
godot --headless --export-debug "Android" build/blacktail-alley-run-debug.apk
```

## Project structure
```
project.godot, export_presets.cfg   Godot project + Android export preset
scenes/main.tscn                    entry scene
scripts/game.gd                     game states, physics, level generation, input, tests
scripts/cat2d.gd                    procedurally drawn + animated cat
scripts/rooftop.gd                  runnable building, obstacles, gaps
scripts/backdrop.gd                 parallax city layers
scripts/ink.gd                      hand-drawn drawing helpers
scripts/hud.gd, title_logo.gd       HUD; home-screen title, ribbon and best-score sign
scripts/fish.gd, dust.gd, sfx.gd    collectible, dust puffs, synthesised audio
scripts/cat_rig.gd, cat_view.gd,    earlier 3D cat prototype (no longer used by the game)
  pal.gd, assets/cat/
assets/fonts/                       Teko Bold font + OFL licence
tools/                              run_tests.sh, capture.sh, cat_sheet.gd (dev only, not exported)
docs/art-reference.png              visual reference (not exported)
```

## Known limitations
- Debug APK only; no signed release build yet.
- Not yet tested across a range of physical Android devices.
- The sound setting resets on each launch (only the best score is saved).
- All art is procedural vector drawing; it follows the reference style but is not painted artwork.

## Contributing & issues
Bug reports and suggestions are welcome via
[GitHub Issues](https://github.com/teja-bot5/rent-is-due/issues) — please include your
device model, Android version and steps to reproduce. For pull requests, keep changes
focused and run `tools/run_tests.sh` before submitting.

## License
The project's code is released under the [MIT License](LICENSE). Third-party material
keeps its own license and is **not** covered by MIT:
- **Teko** font — © 2023 The Teko Project Authors, SIL Open Font License 1.1
  (`assets/fonts/OFL.txt`), via the `@fontsource/teko` package.
- **Cat model** (earlier 3D prototype) — "Animal Pack Vol.2" by Quaternius, CC0
  (`assets/cat/CREDITS.md`).
- `docs/art-reference.png` is a concept reference image only. It is not part of the game
  and is not licensed under MIT (it shows third-party brand names).

## Attribution
BLACKTAIL is maintained by teja-bot5. Much of the code and documentation was written with
the help of Claude Code (Anthropic's AI coding assistant) at the maintainer's direction;
the commit history records this.
