# VibeWave

A digital mobile theremin controlled by 3D motion in space.

See [docs/PROJECT_DESCRIPTION.md](docs/PROJECT_DESCRIPTION.md) for scope, roadmap and the weekly status log.

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install/linux) (latest stable), e.g. cloned to `~/development/flutter`
- Android SDK with command-line tools (e.g. `~/Android/Sdk`) and accepted licenses: `flutter doctor --android-licenses`
- For the Linux desktop build:

  ```sh
  sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-14-dev
  ```

  `libstdc++-N-dev` must match the newest GCC in `/usr/lib/gcc/x86_64-linux-gnu/`, otherwise linking fails with `cannot find -lstdc++`.

Shell setup (e.g. in `~/.zshrc`):

```sh
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/development/flutter/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

`flutter doctor` should report the Android and Linux toolchains as OK.

## Development

```sh
flutter pub get
flutter analyze
flutter test
```

### Run on an Android phone

1. Enable Developer options and USB debugging on the phone.
2. Connect it over USB and accept the RSA fingerprint prompt.
3. `flutter devices` should list the phone, then:

   ```sh
   flutter run
   ```

### Build

```sh
flutter build apk --debug   # build/app/outputs/flutter-apk/app-debug.apk
flutter run -d linux        # desktop, for UI work (no motion sensors)
```

## CI

GitHub Actions ([.github/workflows/ci.yml](.github/workflows/ci.yml)) runs format check, analyze, tests and a debug APK build on every pull request and push to `main`. The APK is attached to each run as the `vibewave-debug-apk` artifact.
