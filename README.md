# PhonePong

Phone-as-paddle motion table tennis — **UI/UX shell** for the 2-hour hackathon MVP.
This repository contains the **front-end only**. Sensor, audio, haptic, and game-loop
logic are stubbed so the team can wire them in independently.

## Visual Identity

Inspired by classic Mario palette:

| Token            | Hex       | Purpose                          |
| ---------------- | --------- | -------------------------------- |
| Mario Red        | `#E52521` | Ball-far state, primary CTA      |
| Coin Gold        | `#FBD000` | Ball-near state, score chips     |
| Pipe Green       | `#00A651` | Ball-ready state, success        |
| Sky Blue         | `#5C94FC` | Background, calm states          |
| Mario Blue       | `#049CD8` | Accents                          |
| Bowser Black     | `#000000` | 2–3 px outlines (Mario signature)|

## Run

```bash
flutter create --org com.phonepong --project-name phonepong .   # adds android/ ios/ scaffolding
flutter pub get
flutter run
```

> The `flutter create .` step only needs to run once — it adds the platform folders
> without overwriting any of the `lib/` or `pubspec.yaml` files in this repo.

## Screen Flow

```
Home → Safety Reminder → Spatial Scan → Calibration → Game → Result
                                                        ↑       ↓
                                                        └── Play Again
```

## Mock Game Interactivity

Inside `GameScreen` a slide-up **Demo Controls** sheet lets you:

- Toggle ball state `far` / `near` / `ready`
- Trigger blinks on left / right / top / bottom edges
- Fire `hit`, `smash`, or `miss` events
- Bump score / rally counters

All sensor & audio calls are placeholder `// TODO(member-N)` stubs in
`lib/features/game/game_controller.dart`.

## Accessibility

All four toggles live in **Settings** and are read by every screen via
`A11yController` (a `ChangeNotifier` singleton-ish):

- High contrast (boosts outlines, removes translucency)
- Larger touch targets (54 pt buttons)
- Reduced motion (disables blinks/pulses, keeps color states)
- Left / right-handed UI mirror (flips bottom controls & HUD chips)

## Architecture (hackathon edition)

```
lib/
  main.dart
  app.dart                              # MaterialApp + routes
  theme/mario_theme.dart                # tokens + ThemeData
  core/
    accessibility/a11y_controller.dart
    painters/                            # CustomPainter assets
    widgets/                             # reusable Mario widgets
  features/
    home/         home_screen.dart
    safety/       safety_screen.dart
    scan/         spatial_scan_screen.dart
    calibration/  calibration_screen.dart
    game/
      game_controller.dart               # ValueNotifier game state
      models/game_state_models.dart
      game_screen.dart
      widgets/
    results/      result_screen.dart
    settings/     settings_screen.dart
```

State management is intentionally lightweight — `ValueNotifier` /
`ChangeNotifier` + `ValueListenableBuilder` — per the hackathon brief. Swap to
`get_it` + `watch_it` post-MVP if the codebase grows.
