# Build your first game with AI — short student guide

**Goal:** make a small 2D action platformer with your own hero, enemy, boss and background.

**Tools:** Godot 4, Visual Studio Code + Codex, and ChatGPT/image tools for artwork.

Start in a **new empty folder**. Send one prompt at a time. After each step: **play → check → change one thing → save a backup**.

## Start — Tell Codex how to help

```text
- I am learning to build a Godot 4 game from an empty folder.
- Complete only the step I send, using simple code and placeholders.
- Explain how to run it and give me a short checklist.
- Say what you actually checked and what I must check myself.
- Keep docs/progress.md updated; mark student checks only after I confirm them.
- Stop after each step so I can try it.
```

## 1. Create the base game

**Send to Codex:**

```text
- Create a Godot 4 project using GDScript and the Compatibility renderer.
- Use a 960 x 540 window, a plain floor and a colored player placeholder.
- Add A/D movement, Space to jump, gravity and floor collision.
- Allow jumping only when grounded and add a following camera.
- Expose speed and jump strength in the Inspector.
- Explain how to open and run the game.
```

- [ ] Player moves, jumps and lands.
- [ ] I changed speed or jump strength and explained the difference.

## 2. Make a short level

**Send to Codex:**

```text
- Add three broad platforms and a clear exit marker.
- Make every required jump possible with the current normal jump.
- Return the player safely to the start after falling.
- Keep the route simple and uncluttered.
```

- [ ] I can reach the exit and recover from a fall.
- [ ] I can explain the purpose of each platform.

## 3. Add combat

**First send to Codex:**

```text
- Add C for a facing-direction melee attack and a practice target with health.
- Show the swing, damage the target once per attack, and restore movement afterward.
```

**After checking the attack, send:**

```text
- Replace the target with one enemy that approaches, warns, attacks and recovers.
- Add player health, an HP bar and brief protection after damage.
- At zero HP, show Retry and reset health, enemies and player control.
```

- [ ] Attacks hit once per swing and only within reach.
- [ ] Enemy warnings, player death and Retry work.

## 4. Add a boss

**Send to Codex:**

```text
- Make the exit lead to a separate boss arena.
- Add a placeholder boss with health, a warned swipe and a warned pounce.
- Give attacks recovery time and keep both actors inside the arena.
- Show boss HP here only, then a victory message when defeated.
```

- [ ] I can enter the arena, avoid attacks and defeat the boss.
- [ ] I adjusted one attack timing and explained how difficulty changed.

## 5. Create your hero

**Send to ChatGPT/image tool:**

```text
- Design my original side-view hero: [appearance, colors and weapon].
- Use a transparent PNG, clear silhouette and no text or scenery.
- First show one full-body idle pose for approval.
```

**After approval, request ONE animation at a time:**

```text
- Animate my approved hero: [idle / walk / jump / attack / hurt / death].
- Keep consistent proportions, canvas size, alignment and transparency.
- Keep the entire weapon inside every frame.
- Supply numbered PNG frames or a regular-grid sprite sheet.
- Also provide a GIF preview if supported.
```

**Then send to Codex:**

```text
- Inspect my hero frames in [folder path] and replace the placeholder visuals.
- Use AnimatedSprite2D; preserve existing physics and collision.
- Keep size and foot alignment stable and report missing frames.
- Match attack damage timing to the visible strike.
```

- [ ] Hero animations stay aligned and work during gameplay.
- [ ] I identified which attack frames should deal damage.

**GIF = motion preview. PNG frames/sprite sheet = game assets.** Generated frames may need corrections before importing.

## 6. Customize the enemy and boss

Repeat for **one character at a time**.

**Send to ChatGPT/image tool:**

```text
- Design my [enemy / boss]: [description], matching the attached hero style.
- First show a transparent idle PNG for approval.
- Then create movement, attack, hurt and death frames separately.
- For the boss, include swipe, pounce warning and pounce.
- Keep consistent canvas size and alignment; supply PNG frames and optional GIF previews.
```

**Then send to Codex:**

```text
- Replace the [enemy / boss] visuals using files in [path].
- Preserve behavior, health, collision and arena boundaries.
- Align animations with attack warnings and damage timing.
```

- [ ] Enemy and boss remain readable, hittable and defeatable.
- [ ] I checked their animation size and alignment while playing.

## 7. Add a background

**Send to ChatGPT/image tool:**

```text
- Create a 1920 x 1080 side-view background for [my setting].
- Match my character palette, with subdued scenery and one distant landmark.
- No characters, text, UI or walkable platforms. Export a PNG.
```

**Then send to Codex:**

```text
- Add my background from [path], preserving aspect ratio.
- Keep the player and platform edges clearly visible.
- Expose brightness and scale; preserve level collision.
```

- [ ] Background fits without hiding the player or landing edges.
- [ ] I compared two brightness settings and chose the clearer one.

## 8. Finish and share

**First send to Codex:**

```text
- Add a title menu with Start Game and Quit.
- After boss defeat, show a completion screen with Return to Title.
- Starting again resets health, enemies and the boss.
```

**After playing through it, send:**

```text
- Help me export a Windows x86_64 release with matching Godot export templates.
- Keep builds outside the source folder and exclude development previews.
- Include required assets and a short controls README.
- Explain how to ZIP the entire exported folder for a friend.
```

- [ ] Start → level → boss → completion → title works.
- [ ] A friend can extract the ZIP and play the exported game.

## If something breaks

```text
- Expected: [what should happen].
- Actual: [what happens].
- Steps: [inputs and location].
- Evidence: [screenshot or exact error].
- Make a small relevant fix and tell me how to check it.
```

## Optional later

- Double jump, dash and combos.
- Rising Slash, Downward Slash and Crescent.
- Checkpoints, seals and Wisp guidance.
- Lighting, sound, petals, platform artwork and cutscenes.

**Teacher reference:** [full lesson guide](ai_game_creation_student_course_full.md).

This creates a simpler game with the same basic structure. Add optional lessons to move closer to The Silent Keep: Moonlit Oath. Rehearse the prompts in a fresh project before teaching.
