# Installation and Android toolchain readiness (Phase 6)

## Windows Java/Gradle requirements

- Flutter is configured to use JDK 17 for Flutter Android commands:
  ```powershell
  flutter config --list
  ```
  Expected setting: `jdk-dir: C:\Program Files\Java\jdk-17`.
- The application compiles Java source/target compatibility at 17. Do not
  change Kotlin, Gradle, AGP, or Java versions merely to address a shell-path
  mismatch.
- The current shell may still have `JAVA_HOME` and `java -version` pointing to
  JDK 26. Direct `android\gradlew.bat` consequently uses JDK 26, while Flutter
  commands use Flutter's configured JDK directory. Prefer `flutter build` and
  other Flutter commands for this project. If direct Gradle use is required,
  first set `JAVA_HOME` to the existing JDK 17 for that shell session and
  confirm it with `android\gradlew.bat -version`; do not change it globally
  without a separate toolchain decision.
- Keep the project path free of `&` (or similar shell metacharacters). The
  Flutter project lives at `Border Safety Alert System`, not the similarly
  named folder containing `&`.

## Prerequisites

- Flutter SDK (stable), Dart SDK bundled, Android Studio + Android SDK, Git, Python 3.10+.

## Verify (Windows PowerShell, run from repo root)

```powershell
flutter --version
flutter pub get
flutter analyze
flutter test
```

## Android device readiness

The release APK can be built, but the last `flutter doctor -v` audit reported
the Android SDK command-line tools missing and Android license status unknown.
Before using a physical Android device, install **Android SDK Command-line
Tools (latest)** through Android Studio's SDK Manager (or the official SDK
tools), then run:

```powershell
flutter doctor --android-licenses
flutter doctor -v
```

Accept the licenses and confirm that the Android toolchain is marked healthy.
No Android device was connected during the Phase 1–6 verification, so physical
GPS behavior remains unverified.

## Python (future ML/backend scaffolding only)

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r ml\requirements.txt
pip install -r backend\requirements.txt
```

## Notes

- Do NOT run `git add` from `C:\Users\jaget` — that folder is itself a git repo (your home
  directory). Initialize a dedicated repo for this project folder before committing, or ask
  before any git operation.
- APK builds come in later phases (`flutter build apk`).
- Phase 6 has already produced a release APK; Phase 7 must not begin until its
  separately planned verification is approved.
