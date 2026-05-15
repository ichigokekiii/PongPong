# PongPong

Flutter multiplayer MVP scaffold for a motion-controlled table tennis game where each player uses their phone as the paddle.

## Current App Flow

`Home -> Safety -> Multiplayer Setup -> Host QR / Join QR -> Shared Spatial Creation -> Local Calibration -> Game -> Results`

## Multiplayer Setup

- One phone hosts the session
- The second phone joins by scanning the host QR code or pasting the payload
- Both phones must connect on the same local network
- After pairing, both phones enter shared spatial creation
- The host controls the shared scan and the joiner mirrors the progress
- After spatial creation, each phone calibrates locally

## Current Dependencies

- `sensors_plus`
- `camera`
- `audioplayers`
- `vibration`
- `qr_flutter`
- `mobile_scanner`

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
7. Make sure both demo phones are on the same local network for host/join testing.

## Android Notes

Android support is scaffolded and the local SDK basics are ready. Main-manifest internet permission is enabled for the local multiplayer session.

## Product Spec

The gameplay and MVP requirements live in [agent.md](/Users/jc/PongPong/agent.md).
