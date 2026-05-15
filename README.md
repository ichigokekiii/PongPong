# PhonePong

A Flutter-based motion table tennis game where the phone becomes the
paddle, the ball is virtual, and the room becomes the court. The full
design lives in [`agent.md`](./agent.md).

## App flow

```
Home → Safety Reminder → Spatial Scan → Calibration → Game → Results
```

## Feature ownership

| Area | Owner | Key files |
|---|---|---|
| App shell + game flow | Member 1 | `lib/main.dart`, `lib/app/*`, `lib/features/home/*`, `lib/features/onboarding/*`, `lib/features/results/*` |
| Spatial scan / play area | HART | `lib/features/scan/scan_screen.dart`, `lib/features/scan/scan_controller.dart`, `lib/features/scan/scanned_area_model.dart` |
| Motion paddle + hit detection | SETH | `lib/core/sensors/motion_sensor_service.dart`, `lib/features/game/hit_detection_service.dart`, `lib/features/game/paddle_model.dart` |
| Sound + light/blinking feedback | JOHN | `lib/core/audio/game_audio_service.dart`, `lib/core/haptics/haptic_service.dart`, `lib/features/game/ball_feedback_widget.dart`, `lib/features/game/ball_model.dart` |

## Spatial scan (HART)

The scan screen walks the player through:

1. **Capture left edge** — sets the left boundary.
2. **Capture right edge** — locks the lane width.
3. **Capture forward length** — sets the rally depth and derives near/hit zones.
4. **Confirm play area** — review width/length and tap to enter calibration.

Width and length values are stored in `ScannedArea` and forwarded all the
way to the Game and Results screens via route arguments.

## Motion paddle (SETH)

`MotionSensorService` subscribes to the accelerometer and gyroscope
through `sensors_plus`. Magnitudes are compared against the calibrated
`SwingProfile` to classify each swing as:

- `weak` → counts as a miss (swing too soft to return the ball)
- `normal` → counts as a clean hit during the green window
- `smash` → counts as a smash during the green window
- swinging outside the green window → miss (bad timing)
- no swing during the green window → miss (no swing)

`HitDetectionService` is a pure function over `(BallState, SwingResult)`
that returns a `HitOutcome` (`hit`, `smash`, `earlyMiss`, `weakMiss`,
`noSwing`), so the rules are easy to unit test.

## Sound + light (JOHN)

- **Color states** — `red` (far), `yellow` (near), `green` (ready).
- **Blinking** — `BallFeedbackArena` runs an `AnimationController` whose
  duration is derived from `Ball.blinkIntervalMs`, which shrinks as the
  ball speed goes up. The same blink drives the four edge bars
  (left/right/top/bottom) and the center pulse.
- **Sound** — `GameAudioService` uses `SystemSound` clicks + Flutter
  haptics to deliver approach ticks (rate scales with ball speed),
  hit clicks, smash clicks (heavy haptic), and miss alerts.
- **Speed coupling** — every smash bumps `Ball.speed`, which feeds back
  into both the blink rate and the audio tick interval.

## Getting started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The motion sensors and camera require a real device. On desktop / web
the screen falls back to **Manual Hit Override** and **Manual Smash
Override** buttons so the rest of the flow can still be demonstrated.
