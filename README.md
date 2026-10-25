# BLACKTAIL — Alley Run



![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)




![Engine](https://img.shields.io/badge/Godot-4.7.2-478CBF?logo=godotengine&logoColor=white)




![Language](https://img.shields.io/badge/GDScript-blue)




![License](https://img.shields.io/badge/license-MIT-green)




![Offline](https://img.shields.io/badge/works-offline-black)



An offline 2D side-scrolling endless runner for Android. Play as a black cat with amber eyes, racing across hand-drawn Indian rooftops. Jump between buildings, dodge rooftop obstacles, slide under hanging rugs and cables, and collect fish.

Maintained by [teja-bot5](https://github.com/teja-bot5).

---

## 📥 Download for Android

**[⬇️ Download BLACKTAIL v1.0.0 — Android APK](https://github.com/teja-bot5/blacktail-alley-run/releases/latest)**

1. Download `blacktail-alley-run-debug.apk` from the latest release.
2. Open the downloaded APK on your Android phone.
3. If prompted, allow installation from your browser or file manager.
4. Install and play.

> [!WARNING]
> This is a **debug APK** intended for testing. It is not a Play Store release. Android may display a security warning when installing it.

---

## ✨ Features

- 🐈‍⬛ Expressive, animated black cat with running, jumping, sliding, and sitting animations.
- 🏙️ Hand-drawn comic-style Indian rooftops with exposed brick, cracked plaster, water tanks, AC units, rugs, wires, and layered city backgrounds.
- 🚧 Clear obstacle actions: jump over crates, broken walls, water tanks, and AC units; slide under hanging rugs and low cable bundles.
- ♾️ Endless rooftop generation with gradually increasing speed and difficulty.
- ❤️ Three hearts, 🐟 fish collectibles, score, saved best score, and instant restart.
- 🔊 Synthesised sound effects, ambience, and music with an ON / LOW / OFF control.
- 📴 Works fully offline after installation.

---

## 🎮 Android Controls

| Action | Control |
|--------|---------|
| **Play** | Tap **PLAY** on the home screen |
| **Jump** | Tap anywhere on the screen or use the on-screen cat button |
| **Slide** | Swipe down or use the on-screen arrow button |
| **Pause** | Tap the pause button at the top right |
| **Sound** | Tap **SOUND** to cycle through ON, LOW, and OFF |

---

## 🛠️ Developer Setup

BLACKTAIL is built with **Godot 4.7.2** and **GDScript**.

### Requirements

- [Godot 4.7.2](https://godotengine.org/download/) with the standard editor
- Android export templates and the Android SDK (to build the APK locally)

### Run the Game

Open `project.godot` in Godot and launch the main scene.

### Run Automated Tests

```bash
GODOT=/path/to/godot tools/run_tests.sh
```

The tests cover obstacle actions, rooftop gaps, touch controls, endurance, and restart behaviour.

### Build the Android APK

For Android export setup and the complete build configuration, see the [Android build workflow](.github/workflows/android-apk.yml).

---

## 📁 Project Structure

```text
project.godot, export_presets.cfg   Godot project and Android export preset
scenes/main.tscn                    Main game scene
scripts/game.gd                     Game states, physics, level generation, and input
scripts/cat2d.gd                    Procedurally drawn and animated cat
scripts/rooftop.gd                  Rooftops, obstacles, and gaps
scripts/backdrop.gd                 Parallax city backgrounds
scripts/ink.gd                      Hand-drawn drawing helpers
scripts/hud.gd                      Heads-up display
scripts/title_logo.gd               Home-screen title and best-score sign
scripts/fish.gd, dust.gd, sfx.gd    Collectibles, dust effects, and synthesised audio
assets/fonts/                       Teko Bold font and its licence
icon.png, icons/                    Game icon and Android launcher icons
tools/                              Development utilities and automated tests
docs/art-reference.png              Visual reference, not exported with the game
```

---

## ⚠️ Known Limitations

- This is an early debug release, not a Play Store-ready production build.
- The game has not been tested across a wide range of physical Android devices.
- The sound setting resets when the game is relaunched.
- Artwork is procedurally drawn and inspired by the reference style.

---

## 🐞 Bug Reports and Suggestions

Report bugs or suggest improvements through [GitHub Issues](../../issues). Please include:

- Your Android device model
- Android version
- Steps to reproduce the issue

### Contributing

Contributions should remain focused. Run the test suite before submitting changes:

```bash
tools/run_tests.sh
```

---

## 📄 License

The project's code is released under the [MIT License](LICENSE).

Third-party material retains its own licence and is **not** covered by the MIT License:

| Asset | Licence | Details |
|-------|---------|---------|
| Teko font | SIL Open Font License 1.1 | [`assets/fonts/OFL.txt`](assets/fonts/OFL.txt) |
| Quaternius cat model | CC0 (used in the earlier 3D prototype) | [`assets/cat/CREDITS.md`](assets/cat/CREDITS.md) |
| `docs/art-reference.png` | Visual reference only, not included in the game | — |

---

## 🙌 Attribution

BLACKTAIL is maintained by [teja-bot5](https://github.com/teja-bot5). AI assistance was used during development, and the commit history preserves the project's contribution history.
