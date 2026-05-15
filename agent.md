# Table Tennis Motion Game MVP

## Project Overview

This project is a Flutter-based mobile game for both iPhone and Android. The app is a table tennis-inspired motion game where the user plays using only their phone. The game takes inspiration from the Nintendo Switch motion-control experience and the Xbox Kinect-style space setup, but instead of using external controllers, cameras, tables, paddles, or balls, the phone itself becomes the main controller and paddle.

The core idea is simple:

> One phone hosts the multiplayer session, the second phone joins it, both phones enter a shared spatial-creation flow, and then each player uses their phone as a virtual paddle to hit an invisible virtual ping-pong ball through motion controls, screen indicators, blinking lights, sound cues, and haptic feedback.

This app does not require a physical table, a physical paddle, or a physical ball. The gameplay is created through the phone's camera, motion sensors, screen, and speakers.

---

## Core Concept

The game creates a virtual table tennis experience using five main pillars:

1. **Multiplayer Session Setup**  
   One phone hosts the match and the other phone joins through a QR code on the same local network.

2. **Shared Spatial Setup**  
   After both phones connect, they enter the spatial-creation flow together. The host controls the scan and the joiner mirrors the progress.

3. **Phone-as-Paddle Gameplay**  
   Each player holds their phone and swings it like a ping-pong paddle. The app detects swing motion using the phone's sensors.

4. **Virtual Ball Feedback**  
   There is no physical ball. The ball is represented through screen colors, blinking indicators, screen-edge direction cues, sound, and vibration.

5. **Table Tennis Rally Logic**  
   The player must time their swing correctly to hit the virtual ball, continue the rally, score points, and perform smashes.

---

## MVP Definition

The MVP is a Flutter-based local multiplayer motion table tennis game where one phone hosts, the second phone joins through a QR connection, both phones complete shared spatial creation, each player calibrates locally, and then they use their phones as paddles to track a virtual invisible ball through screen-edge indicators, color states, blinking, sound, and haptics before swinging to hit, rally, or smash based on motion sensor input.

The MVP should include the complete core identity of the app:

- Flutter app for iPhone and Android
- Local multiplayer host/join flow
- QR-based session join
- Camera-based spatial scanning flow
- Length and width area setup
- Virtual play space creation
- Phone-as-paddle gameplay
- No physical table needed
- No physical ball needed
- Virtual ball location through screen indicators
- Ball distance through color feedback
- Ball direction through phone screen edges
- Ping-pong sound cues
- Faster blinking and faster sound when the ball speed increases
- Swing detection using phone sensors
- Smash detection based on swing strength
- Game logic for hit, miss, rally, score, and speed changes

---

## Gameplay Summary

The players start the app, decide which phone will host, connect the second phone through the host QR, complete shared spatial creation, calibrate locally, and then begin a rally. A virtual ball moves inside the scanned play space. Since the ball is invisible in the real world, the app communicates its position and timing using the phone screen and sound.

The screen uses color indicators:

| Color | Meaning |
|---|---|
| Red | The ball is far |
| Yellow | The ball is near |
| Green | The ball is ready to hit |

The edges of the screen indicate the ball's direction:

| Screen Indicator | Meaning |
|---|---|
| Left edge blinking | Ball is coming from the left |
| Right edge blinking | Ball is coming from the right |
| Top edge blinking | Ball is farther/front |
| Bottom edge blinking | Ball is close/near |
| Center pulse | Ball is in the hitting zone |

The player waits until the indicator turns green, then swings the phone like a paddle. The app detects the swing using the accelerometer and gyroscope. If the swing is timed correctly, the player hits the ball and the rally continues. If the swing is too early, too late, too weak, or absent, the player misses.

A strong swing during the correct timing window counts as a smash. A smash makes the next return faster and more intense.

---

## Main Game Flow

```txt
Home Screen
    ↓
Safety Reminder Screen
    ↓
Multiplayer Setup Screen
    ↓
Host QR / Join QR
    ↓
Pair Connected
    ↓
Shared Spatial Creation Screen
    ↓
Confirm Play Area
    ↓
Calibration Screen
    ↓
Game Screen
    ↓
Hit / Miss / Smash Detection
    ↓
Score Update
    ↓
Result Screen
```

---

## Detailed User Flow

### 1. Home Screen

The user opens the app and sees the main menu.

Main options:

- Start Game
- How to Play
- Calibration
- Settings

For the hackathon MVP, the most important button is **Start Game**.

---

### 2. Safety Reminder Screen

Before the game starts, the app reminds the user to clear their surroundings and hold the phone securely.

Possible text:

> Make sure you have enough space around you. Hold your phone firmly and avoid playing near people, pets, glass, or fragile objects.

---

### 3. Multiplayer Setup Screen

The players decide which phone is the host and which phone will join.

Main actions:

- Host Game
- Join Game

The host phone creates the session and shows a QR code.

The joiner phone scans the QR code or pastes the payload to connect.

---

### 4. Shared Spatial Creation Screen

After the two phones connect, both phones enter the shared spatial-creation flow.

The host controls the scan using the phone camera or a simulated scan UI.

The joiner mirrors the scan progress and waits for the host to confirm the play area.

The scan has two main parts:

#### A. Width Scan

The user scans the left and right boundaries of the play area.

Purpose:

- Determine how wide the virtual court is
- Set the left and right movement limits of the virtual ball

#### B. Length Scan

The user scans the forward/backward area.

Purpose:

- Determine how deep the virtual court is
- Set far, near, and hit zones

---

### 5. Confirm Play Area

After scanning, the app shows that the play area is ready.

Example data:

```txt
Width: 2.5 meters
Length: 3.0 meters
Play Area: Ready
```

For the hackathon MVP, these values can be estimated or simulated as long as the scan flow clearly demonstrates the concept and both phones stay in sync.

---

### 6. Calibration Screen

Each player performs sample swings on their own phone so the app can understand their motion style.

Calibration can include:

- Normal swing test
- Strong swing test
- Left-handed or right-handed setting
- Swing sensitivity adjustment

The goal is to determine basic thresholds for each phone:

- Weak swing
- Normal hit
- Smash

---

### 7. Game Screen

This is the main gameplay screen.

The Game Screen displays:

- Current score
- Rally count
- Ball state color
- Blinking indicators
- Screen-edge direction indicators
- Hit/miss/smash feedback
- Pause button

The virtual ball moves through different states:

```txt
Far → Near → Ready to Hit → Hit or Miss
```

---

### 8. Result Screen

After the rally ends, the app shows the result.

Possible result data:

- Final score
- Longest rally
- Number of hits
- Number of smashes
- Accuracy
- Play again button

---

## Spatial Scanning Logic

The spatial scan starts only after both phones are connected.

The host controls the shared scan and the joiner mirrors the result.

The spatial scan creates a virtual play area using the phone camera.

The app needs to identify or simulate:

- Left boundary
- Right boundary
- Forward length
- Player position
- Near zone
- Far zone
- Hit zone

For the hackathon MVP, the scan can be simplified into a guided multiplayer flow:

```txt
Step 1: Host the session
Step 2: Join the session
Step 3: Scan left boundary
Step 4: Scan right boundary
Step 5: Scan forward length
Step 6: Confirm shared play area
Step 7: Start calibration
```

The important part is that both players feel like they are preparing a real shared play space before the game begins.

---

## Virtual Play Space

Once scanning is complete, the app creates a virtual court.

The virtual court includes:

- Width
- Length
- Ball direction range
- Ball distance zones
- Hit timing zone
- Miss zone
- Player origin point

Example model:

```dart
class PlayArea {
  final double width;
  final double length;

  PlayArea({
    required this.width,
    required this.length,
  });
}
```

---

## Ball Logic

The ball is virtual and does not physically appear in the room. The game calculates where the ball is inside the virtual play space.

The ball has these properties:

- Distance from player
- Direction
- Speed
- Current state
- Hit window timing
- Blink speed

Possible ball states:

```dart
enum BallState {
  far,
  near,
  ready,
  hit,
  smash,
  missed,
}
```

### Ball State Meaning

| Ball State | Meaning |
|---|---|
| far | Ball is still far from the player |
| near | Ball is approaching the player |
| ready | Ball is inside the hit zone |
| hit | Player successfully hit the ball |
| smash | Player hit the ball with strong force |
| missed | Player missed the ball |

---

## Color Indicator Logic

The color of the screen tells the player how close the ball is.

### Red State

Red means the ball is far.

Player action:

- Prepare
- Do not swing yet

### Yellow State

Yellow means the ball is near.

Player action:

- Get ready
- Prepare to swing

### Green State

Green means the ball is in the hit zone.

Player action:

- Swing now

---

## Blinking Logic

The blinking speed represents the urgency and speed of the virtual ball.

| Blink Speed | Meaning |
|---|---|
| Slow blink | Ball is far or slow |
| Medium blink | Ball is approaching |
| Fast blink | Ball is near, fast, or ready to hit |
| Very fast blink | Ball was smashed or speed increased |

After a smash, the next ball should feel faster through:

- Faster blinking
- Faster sound cues
- Shorter reaction time
- Smaller hit timing window

---

## Screen Edge Direction Logic

The phone screen edges show where the virtual ball is coming from.

| Edge | Meaning |
|---|---|
| Left edge | Ball is coming from the left |
| Right edge | Ball is coming from the right |
| Top edge | Ball is far/front |
| Bottom edge | Ball is close/near |
| Center | Ball is ready to hit |

Example:

```txt
Left edge blinking + yellow screen = Ball is approaching from the left
Right edge blinking + green screen = Swing now to the right side
Center green pulse = Ball is directly hittable
```

---

## Sound Logic

Sound helps the player locate and time the invisible ball.

The app should use ping-pong-like audio cues.

Sound feedback can include:

| Sound | Meaning |
|---|---|
| Soft slow ping | Ball is far |
| Louder ping | Ball is closer |
| Faster ping interval | Ball is approaching quickly |
| Sharp hit sound | Successful hit |
| Strong hit sound | Smash |
| Dull sound | Miss or weak hit |

The sound should become faster when:

- The ball approaches
- The rally gets longer
- The previous hit was a smash
- The game speed increases

---

## Phone-as-Paddle Logic

The phone acts as the player's paddle.

The app uses phone sensors to detect the player's swing:

- Accelerometer
- Gyroscope
- Device orientation

The app should detect:

- If the user swung the phone
- How strong the swing was
- Whether the swing happened at the correct time
- Whether the swing was strong enough for a hit
- Whether the swing was strong enough for a smash

Example model:

```dart
class SwingResult {
  final bool isSwinging;
  final double strength;
  final bool isSmash;

  SwingResult({
    required this.isSwinging,
    required this.strength,
    required this.isSmash,
  });
}
```

---

## Hit Detection Logic

The app determines whether the player hit or missed the ball.

### Successful Hit

A hit happens when:

1. The ball is in the green state
2. The player swings during the hit window
3. The swing is strong enough
4. The swing direction is acceptable

Result:

- Score increases
- Rally continues
- Hit sound plays
- Haptic feedback triggers
- Ball returns with adjusted speed

---

### Smash

A smash happens when:

1. The ball is in the green state
2. The player swings during the hit window
3. The swing strength is above the smash threshold

Result:

- Score increases with bonus
- Smash sound plays
- Stronger haptic feedback triggers
- Ball speed increases
- Blink speed increases
- Sound cue speed increases

---

### Miss

A miss happens when:

- The player swings too early
- The player swings too late
- The player does not swing
- The swing is too weak
- The swing direction is wrong

Result:

- Rally ends
- Miss sound plays
- Result screen appears

---

## Basic Game State Logic

The game can use these states:

```dart
enum GameStatus {
  idle,
  scanning,
  calibrating,
  ready,
  playing,
  hit,
  smash,
  missed,
  gameOver,
}
```

Basic loop:

```txt
Start game
    ↓
Ball becomes far
    ↓
Ball becomes near
    ↓
Ball becomes ready
    ↓
Player swings
    ↓
Check swing strength and timing
    ↓
Hit, smash, or miss
    ↓
Continue rally or end game
```

---

## Scoring Logic

Suggested MVP scoring:

| Action | Points |
|---|---:|
| Normal hit | +1 |
| Smash | +3 |
| Consecutive hit streak | Bonus multiplier |
| Miss | End rally |

Example:

```txt
Hit = +1
Smash = +3
Every 5-hit streak = +2 bonus
Miss = game over
```

---

## Suggested MVP Screens

### 1. Splash Screen

Shows the logo or app name.

### 2. Home Screen

Contains:

- Start Game
- How to Play
- Settings

### 3. Safety Reminder Screen

Shows a warning before playing.

### 4. Multiplayer Setup Screen

Contains:

- Host Game button
- Join Game button
- Multiplayer explanation

### 5. Host / Join Screen

Contains:

- Host QR code
- Join QR scanner
- Manual payload fallback
- Connection status

### 6. Shared Spatial Creation Screen

Contains:

- Camera preview or scan simulation
- Scan width step
- Scan length step
- Confirm play area button

### 7. Calibration Screen

Contains:

- Normal swing test
- Smash swing test
- Sensitivity setup

### 8. Game Screen

Contains:

- Score
- Rally count
- Ball state indicator
- Blinking screen
- Edge indicators
- Hit/miss/smash text feedback

### 9. Result Screen

Contains:

- Final score
- Hits
- Smashes
- Accuracy
- Play Again button

---

## Suggested Flutter Folder Structure

```txt
lib/
  main.dart

  app/
    app.dart
    routes.dart
    theme.dart

  features/
    home/
      home_screen.dart

    onboarding/
      safety_screen.dart
      how_to_play_screen.dart

    scan/
      scan_screen.dart
      scan_controller.dart
      scanned_area_model.dart

    calibration/
      calibration_screen.dart
      calibration_controller.dart
      swing_profile_model.dart

    game/
      game_screen.dart
      game_controller.dart
      ball_model.dart
      paddle_model.dart
      game_state_model.dart
      hit_detection_service.dart
      ball_physics_service.dart

    results/
      result_screen.dart

    settings/
      settings_screen.dart
      settings_model.dart

  core/
    sensors/
      motion_sensor_service.dart

    audio/
      game_audio_service.dart

    haptics/
      haptic_service.dart

    storage/
      local_storage_service.dart

    utils/
      math_utils.dart
      vector_utils.dart
```

---

## Main Systems

### 1. App Flow System

Handles:

- Screen navigation
- Start game flow
- Result flow
- App state

---

### 2. Multiplayer + Spatial Setup System

Handles:

- Host session creation
- Join session connection
- QR payload generation and scan
- Camera scan screen
- Width scan
- Length scan
- Play area confirmation
- Virtual play area creation

---

### 3. Motion Sensor System

Handles:

- Accelerometer data
- Gyroscope data
- Swing detection
- Swing strength calculation
- Smash detection

---

### 4. Ball Logic System

Handles:

- Ball state
- Ball speed
- Ball direction
- Ball distance
- Hit timing window

---

### 5. Feedback System

Handles:

- Red/yellow/green indicators
- Edge blinking
- Blink speed
- Sound effects
- Haptic feedback

---

### 6. Score System

Handles:

- Current score
- Rally count
- Smash count
- Accuracy
- Final result

---

## 2-Hour Hackathon Task Delegation

The team has 4 members. Each member should own one clear area of the MVP.

The best split is:

| Member | Role | Main Output |
|---|---|---|
| Member 1 | App Shell + Multiplayer Entry | Working Flutter app with screens, host/join flow, and navigation |
| Member 2 | Shared Spatial Creation | Host-driven scan flow for width and length |
| Member 3 | Motion Paddle + Hit Detection | Phone swing detection and smash logic |
| Member 4 | Sound + Light/Blinking Feedback | Red/yellow/green indicators, edge lights, and sounds |

---

## Member 1: App Shell + Game Flow Lead

### Main Responsibility

Build the Flutter app structure and connect everyone's work together.

### Tasks

- Create the Flutter project structure
- Create the main screens:
  - Home Screen
  - Safety Reminder Screen
  - Multiplayer Setup Screen
  - Host / Join Screen
  - Shared Spatial Creation Screen
  - Calibration Screen
  - Game Screen
  - Result Screen
- Add navigation between screens
- Create a simple game state system
- Add basic score and timer display
- Prepare placeholder widgets for other members' features
- Integrate the scan, sensor, and feedback systems into the Game Screen

### Expected Output After 2 Hours

A working Flutter app where the user can move through this flow:

```txt
Home → Safety Reminder → Multiplayer Setup → Host / Join → Shared Spatial Creation → Calibration → Game → Results
```

This member must make sure the app runs and does not break during the demo.

---

## Member 2: Spatial Scan / Play Area Setup

### Main Responsibility

Build the shared spatial-creation experience that starts after host/join pairing.

### Tasks

- Create the scan setup screen
- Make the host authoritative for scan changes
- Make the joiner mirror scan progress
- Add camera preview or simulated scanning UI
- Add scan steps:
  - Scan left boundary
  - Scan right boundary
  - Scan forward length
  - Confirm play area
- Store scanned values:
  - width
  - length
  - play area size
- Add progress UI:
  - "Scanning width..."
  - "Scanning length..."
  - "Play area ready"
- Pass the shared play area data to the Game Screen

### Expected Output After 2 Hours

A convincing spatial setup flow:

```txt
Host / Join Connected → Scan Left → Scan Right → Scan Forward → Confirm Area → Start Calibration
```

For the hackathon MVP, the spatial scan can be simplified or simulated as long as it clearly communicates the intended concept.

---

## Member 3: Motion Paddle + Hit Detection

### Main Responsibility

Make the phone act like the paddle.

### Tasks

- Use phone sensors:
  - accelerometer
  - gyroscope
- Detect swing motion
- Classify swing strength:
  - weak
  - normal
  - smash
- Send the hit result to the game logic
- Add simple rules:
  - Swing during green = hit
  - Strong swing during green = smash
  - Swing too early = miss
  - Swing too late = miss
  - No swing = miss
- Add temporary debug values on screen:
  - acceleration
  - gyroscope value
  - swing strength
  - detected hit/smash/miss

### Expected Output After 2 Hours

The app can detect when the user swings the phone.

Example:

```txt
Green screen + swing = HIT
Green screen + hard swing = SMASH
No swing = MISS
```

This is one of the most important demo features.

---

## Member 4: Sound + Light/Blinking Feedback

### Main Responsibility

Make the game feel alive using screen indicators and audio.

### Tasks

- Create red/yellow/green ball-distance states
- Add blinking screen indicators:
  - Red = far
  - Yellow = near
  - Green = ready to hit
- Add edge indicators:
  - Left edge blink
  - Right edge blink
  - Top edge blink
  - Bottom edge blink
- Add sound effects:
  - Approaching ball sound
  - Hit sound
  - Smash sound
  - Miss sound
- Make blink speed faster when ball speed increases
- Make sound cues faster when ball speed increases
- Make smash feedback more intense

### Expected Output After 2 Hours

The Game Screen clearly tells the player what is happening:

```txt
Ball far → red slow blink
Ball near → yellow medium blink
Ready to hit → green fast blink
Smash → faster blink + stronger sound
```

This member owns the visual and audio feedback experience.

---

## 2-Hour Development Timeline

### 0 to 15 Minutes: Setup and Agreement

Everyone agrees on:

- Shared app flow
- Shared enums
- Shared data models
- Git branch names
- Who owns which files

Suggested shared enum:

```dart
enum BallState {
  far,
  near,
  ready,
  hit,
  smash,
  missed,
}
```

Suggested game status enum:

```dart
enum GameStatus {
  idle,
  scanning,
  calibrating,
  ready,
  playing,
  hit,
  smash,
  missed,
  gameOver,
}
```

---

### 15 to 60 Minutes: Build Separately

Each member builds their assigned part.

- Member 1 builds screens and navigation
- Member 2 builds scan setup
- Member 3 builds motion detection
- Member 4 builds feedback system

---

### 60 to 90 Minutes: Integration

Connect the systems:

```txt
Shared scan data → Game Screen
Motion swing → Hit detection
Ball state → Blinking UI
Ball state → Sound feedback
Hit result → Score update
Miss result → Result screen
```

---

### 90 to 120 Minutes: Demo Polish

Focus on making the demo clear and stable.

Priority checklist:

- App opens correctly
- Navigation works
- Host / join flow works
- Shared scan flow works
- Game screen shows indicators
- Swing detection works
- Hit/smash/miss feedback appears
- Score updates
- Result screen works

---

## Git Branch Suggestion

Each member should work on a separate branch.

```txt
main
feature/app-shell
feature/spatial-scan
feature/motion-paddle
feature/feedback-system
```

Suggested workflow:

```bash
git checkout -b feature/app-shell
```

After finishing:

```bash
git add .
git commit -m "Add app shell and game flow"
git push origin feature/app-shell
```

Then merge carefully into `main` or through pull requests.

---

## Files Each Member Can Own

### Member 1

```txt
lib/main.dart
lib/app/app.dart
lib/app/routes.dart
lib/features/home/home_screen.dart
lib/features/onboarding/safety_screen.dart
lib/features/game/game_screen.dart
lib/features/results/result_screen.dart
```

### Member 2

```txt
lib/features/scan/scan_screen.dart
lib/features/scan/scan_controller.dart
lib/features/scan/scanned_area_model.dart
```

### Member 3

```txt
lib/core/sensors/motion_sensor_service.dart
lib/features/game/hit_detection_service.dart
lib/features/game/paddle_model.dart
```

### Member 4

```txt
lib/core/audio/game_audio_service.dart
lib/core/haptics/haptic_service.dart
lib/features/game/ball_model.dart
lib/features/game/ball_feedback_widget.dart
```

---

## Demo Goal

The demo should prove this core flow:

```txt
Host session → Join session → Shared spatial creation → Local calibration → Start game → Ball indicator appears → User swings phone → App detects hit/smash/miss → Score updates → Result screen
```

As long as this flow works, the MVP successfully communicates the full game idea.

---

## What Not to Prioritize During the 2-Hour MVP

Do not spend time on:

- Login/signup
- Database
- Online multiplayer beyond local host/join
- Leaderboards
- Complex account system
- Advanced settings
- Perfect AR measurement
- Highly complex 3D physics
- Over-polished animations

The priority is to make the core game interaction work.

---

## Final MVP Statement

This app is a tableless and ball-less table tennis-inspired mobile game where one phone hosts, the other phone joins, both phones create a shared play space, and then each player uses their phone as the paddle. The game combines multiplayer setup, spatial creation, motion controls, sound feedback, blinking screen indicators, and timing-based table tennis logic into one Flutter mobile experience.
