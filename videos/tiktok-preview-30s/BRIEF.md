---
workflow: general-video
flow: automation
storyboard: no
message: "One-thumb samurai duels, endless. Install now."
destination: tiktok
aspect: 1080x1920
language: en
length: 30s
angle: product-promo
---

## Intent

A 30-second vertical TikTok preview for **Samurai**, an endless mobile action
game built in Godot 4. The audience is mobile gamers scrolling TikTok — the
piece has 3 seconds to earn the next 27. Tone: moody, confident, brutal; the
game's dark palette (near-black violet `#171212`) and crisp SVG silhouettes
set the look. Payoff: a strong hook, a short combat crescendo of slashes +
knockback + screen shake, and a clear install CTA.

The game's own visual language is flat vector (SVG samurai, SVG enemy, SVG
ground tile) so the preview recreates "gameplay feel" with those exact
sprites — same character you'd see on first launch — rather than invented
mockups. If real captured gameplay arrives later, scenes can swap to video
clips on the same timeline.

## Assets

- assets/samurai.svg — player sprite, from the Godot project
- assets/enemy.svg — enemy sprite, from the Godot project
- assets/ground.svg — ground tile, horizon anchor
- assets/icon.svg — game icon, used in logo/CTA

## Customizations

- Slash VFX between combat beats (matches the game's slash arc)
- Screen shake on heavy hits (matches `camera_shake.gd` in the game)
- Dark-violet palette locked to `#171212` background per `project.godot`
- Japanese-flavored BGM bed, ducked under any on-screen text/number hits
- Big-type kinetic lower-third hook, closing CTA card with icon

## Notes

- Game source lives at `../../` (Godot 4.3 project).
- No captured gameplay footage yet — all visuals recreated from the game's SVGs.
- Must read at 60fps thumb-scroll speed: no slow fades under 0.3s hold.
- Deliverable: single MP4, 1080x1920, 30.0s.
