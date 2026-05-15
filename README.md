# PongPong

Flutter MVP scaffold for a motion-controlled table tennis game where the phone acts as the paddle.

## Current Scaffold

- iOS and Android targets are enabled
- Bundle id / application id: `com.jc.pongpong`
- Initial app flow: `Home -> Safety -> Scan -> Calibration -> Game -> Results`
- Core packages added for upcoming motion game work:
  - `sensors_plus`
  - `camera`
  - `audioplayers`
  - `vibration`

## Run The Project

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## iPhone Setup

1. Connect the iPhone to the Mac with a cable.
2. Trust the Mac on the iPhone if prompted.
3. Enable `Developer Mode` on the iPhone.
4. Open [ios/Runner.xcworkspace](/Users/jc/PongPong/ios/Runner.xcworkspace).
5. In Xcode, select the `Runner` target, then set:
   - your Apple ID team under `Signing & Capabilities`
   - a unique bundle identifier if `com.jc.pongpong` conflicts on your account
6. Choose your physical iPhone as the run destination in Xcode once it appears.
7. Back in the terminal, verify detection:

```bash
flutter devices
flutter run -d <your-iphone-device-id>
```

## Android Notes

Android support is scaffolded and the local SDK basics are ready. Full Android device testing is still intentionally deferred.

```bash
flutter doctor -v
```

If `adb` is not found in a new terminal, reload your shell after the `~/.zshrc` update from this setup pass.

## Product Spec

The gameplay and MVP requirements live in [agent.md](/Users/jc/PongPong/agent.md).
