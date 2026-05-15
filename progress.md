# PongPong Progress

## Status

The app flow now supports the multiplayer-first MVP path: host, join, pair, shared spatial creation, local calibration, then game. The main remaining blockers are dependency resolution and full device verification on two physical phones.

## Completed

- [x] Reviewed the product spec in [agent.md](/Users/jc/PongPong/agent.md)
- [x] Added the multiplayer setup route after safety
- [x] Added host and join screens
- [x] Added QR payload generation and QR scan entry points
- [x] Added local-network WebSocket session scaffolding
- [x] Added shared spatial-creation flow where the host controls scan progress
- [x] Added local calibration waiting logic so both phones must be ready before game start
- [x] Updated iOS local-network permission text
- [x] Updated Android internet permission
- [x] Updated [README.md](/Users/jc/PongPong/README.md), [agent.md](/Users/jc/PongPong/agent.md), and [progress.md](/Users/jc/PongPong/progress.md) to reflect the multiplayer-first setup flow

## In Progress

- [ ] Resolve new Flutter dependencies with `flutter pub get`
- [ ] Run `flutter analyze`
- [ ] Run `flutter test`

## Next Steps

- [ ] Verify host flow on phone 1:
  - `Home`
  - `Safety`
  - `Multiplayer Setup`
  - `Host QR`
  - `Shared Spatial Creation`
  - `Calibration`
  - `Game`
  - `Results`
- [ ] Verify join flow on phone 2:
  - `Home`
  - `Safety`
  - `Multiplayer Setup`
  - `Join QR`
  - `Shared Spatial Creation`
  - `Calibration`
  - `Game`
  - `Results`
- [ ] Confirm both phones can connect on the same local network
- [ ] Confirm the host can change scan values and the joiner mirrors them
- [ ] Confirm host confirmation moves both phones into calibration
- [ ] Confirm both phones must finish calibration before gameplay starts

## Current Markdown Files

- [README.md](/Users/jc/PongPong/README.md)
- [agent.md](/Users/jc/PongPong/agent.md)
- [flutter-expert.md](/Users/jc/PongPong/flutter-expert.md)
- [progress.md](/Users/jc/PongPong/progress.md)
- [ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md](/Users/jc/PongPong/ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md)

## Notes

- The multiplayer MVP assumes both phones are on the same local network.
- The join flow supports QR scanning and manual payload paste as a fallback.
- Full two-device validation still needs to happen on real hardware.
