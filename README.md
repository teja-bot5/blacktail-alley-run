# RENT IS DUE

A portrait-first 2D dark-comedy endless arcade-management game. Manage one absurd apartment floor at a time, balance cash and chaos, and see how long you can keep your landlord licence.

## Features
- Minimal-vector style built from HTML/CSS/SVG-like shapes
- Four tenants: ghost, vampire, worm and chicken
- Data-driven events with choices and consequences
- Timed emergency events and untimed ordinary complaints
- Endless floor progression, cash and chaos failure conditions
- Local best-floor and best-score records
- Vite web build, Vitest rules tests, Capacitor Android wrapper
- GitHub Actions workflow that produces a debug APK artifact

## Requirements
Node.js 20+ and npm. Android Studio is not required to build the APK through GitHub Actions.

## Run locally
```bash
npm ci
npm test
npm run dev
```
Open the URL Vite prints. On a phone, the device and development computer must be on the same network if using a local dev server.

## Build the web version
```bash
npm run build
```

## Build Android locally (optional)
```bash
npm ci
npm run build
npx cap add android
npx cap sync android
```
Then build `android/app` with Android Studio or Gradle on a machine with the Android SDK configured.

## Download an APK using GitHub Actions from your phone
1. Create a GitHub repository and upload/push all files in this project.
2. Open the repository's **Actions** tab.
3. Select **Build RENT IS DUE Android APK** and tap **Run workflow**. The workflow also runs on pushes to `main`.
4. Open the completed run. If it fails, open the failed step's logs and fix that issue before retrying.
5. Under **Artifacts**, download `rent-is-due-debug-apk` and extract the ZIP to obtain `app-debug.apk`.
6. Open the APK on Android to install it. You may need to allow installs from the browser or file manager you used.

The workflow creates a debug APK for testing, not a signed Play Store release. The repository and APK are not created automatically by this project ZIP; you must upload the project and run the workflow.

## Notes
- The game is offline after it loads; fonts are imported from Google Fonts and fall back to system fonts if unavailable.
- Records are stored in the WebView/browser local storage.
- Emergency events pause when the app is hidden. A timed emergency is resolved once per event.
- This is an MVP scaffold; adjust event balance and expand tenant/event variety after play-testing.
