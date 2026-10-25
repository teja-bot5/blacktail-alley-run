# BLACKTAIL: ALLEY RUN (prototype)

An offline 3D endless runner for Android about a black cat with amber eyes,
racing across warm, hand-drawn South Asian rooftops. Built with Godot 4 + GDScript.

> **Status: cat-movement prototype.** This build exists to judge the cat's
> animation before the full runner is built. The previous web game
> ("RENT IS DUE") is preserved on the `legacy/rent-is-due` branch.

## Try the prototype
- **Swipe** ← → to switch lanes, ↑ to jump, ↓ to slide (arrow keys / WASD on desktop).
- **SLOW-MO** plays at 0.3× so you can inspect the motion.
- **CAMERA** cycles chase / side / front views.
- **AUTO** lets the autopilot run the course hands-free.

## Get the APK from your phone
1. Open the repository's **Actions** tab → **Build Blacktail Android APK** → **Run workflow**
   (pick the branch you want to build).
2. When the run is green, download the `blacktail-alley-run-debug-apk` artifact,
   unzip it and open `blacktail-alley-run-debug.apk`.

It is a debug build signed with a throwaway key, for testing only.

## How the cat moves
The CC0 cat model only ships Idle and Walking clips, so `scripts/cat_rig.gd`
generates all running-game motion procedurally on the model's 20-bone skeleton:
a rotary-gallop gait with spine flex/extension, folding legs and planted paws,
anticipation crouch, take-off/tuck/reach jump arcs, landing squash, belly slide,
banked sharp turns with a C-curved spine, and a spring-driven tail that
counter-balances turns and jumps. Eyes (with blinks and pupil dilation) are added in code.

## Project layout
```
project.godot, export_presets.cfg
assets/cat/        CREDITS.md (Cat.fbx, CC0 by Quaternius, is fetched by CI)
scenes/            prototype.tscn
scripts/           cat_rig.gd (procedural animation), cat_runner.gd (movement),
                   world.gd (procedural rooftops), prototype.gd (camera, HUD, autopilot),
                   pal.gd (palette + toon/outline materials)
tools/             capture.sh (renders motion preview videos; not exported)
```

## Local commands (Godot 4.7.2)
```bash
godot --headless --import
godot --headless -- --test=20          # autopilot smoke test, prints TEST_RESULT
godot -- --demo --cam=cycle             # watch the autopilot
```

## Credits
Cat model: "Animal Pack Vol.2" by Quaternius, CC0 — see `assets/cat/CREDITS.md`.
