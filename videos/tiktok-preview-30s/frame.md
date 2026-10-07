# Design — Samurai TikTok preview (frame.md)

## Concept angle

**Katana poetry, thumb-sized.** Flat vector silhouettes against a near-black
violet night. Every beat is a composed frame: samurai in still contrapposto,
a slash arc that outruns the eye, an enemy collapsing offscreen. Zero
character detail that the game doesn't already have — if it isn't in the
SVG, it isn't in the trailer.

## Palette (locked to the game)

| Token             | Hex       | Use                                          |
| ----------------- | --------- | -------------------------------------------- |
| `--bg`            | `#17121c` | base background (Godot `default_clear_color`) |
| `--bg-deep`       | `#0d0a12` | vignette corners                             |
| `--ink`           | `#1a1623` | sprite outlines, deep shadow                 |
| `--ground`        | `#2b241e` | ground band                                  |
| `--ground-hi`     | `#5a4432` | ground highlights                            |
| `--skin-player`   | `#f1d9b0` | samurai face                                 |
| `--skin-enemy`    | `#d9b48a` | enemy face                                   |
| `--steel`         | `#9a8f6a` | sword blade                                  |
| `--red`           | `#8a1a1a` | hachimaki, blood                             |
| `--red-hot`       | `#e63946` | slash impact flash                           |
| `--paper`         | `#f3e9d2` | big-type titles, CTA                         |
| `--paper-dim`     | `#c9bfa8` | secondary text, logo mark                    |

Contrast rule: `--paper` on `--bg` passes WCAG AAA (over 15:1). All body text
uses `--paper`; never type on `--ground` directly — raise with a scrim.

## Typography

Embeddable pairing (both ship via Google Fonts, both work in HyperFrames
cloud rendering):

- **Display:** `"Noto Serif JP"` 900 — hook, titles, CTA. Set with
  `letter-spacing: 0.02em` for the English big-type, `0em` for Japanese
  glyphs. The Japanese cut keeps authenticity even when English is set
  in it.
- **UI / small-caps:** `Inter` 700, uppercase, `letter-spacing: 0.18em`
  for the subhead and badge lines ("ENDLESS. MOBILE.").

Load with `<link rel="stylesheet">` to Google Fonts for both families in
`index.html`. Size scale (9:16 at 1080×1920):
- Mega hook: 180px
- Title: 128px
- Sub: 48px
- CTA: 96px

## Composition on 1080×1920

- **Safe zone:** 80px margin all sides; a second 160px top margin keeps
  text clear of TikTok's handle/caption overlays.
- **Focal:** samurai sprite scaled to roughly 540px tall (centered or
  rule-of-thirds-right), sitting on the ground line at ~1540y.
- **Edge anchors:** horizon ground band spans the full width at ~1540–1600y;
  top band for titles.
- **Supporting detail:** slash arc paths, sparks, speed lines — one or two
  per beat, never cluttered.
- **Background:** flat `--bg` with a 25%-opacity radial vignette toward
  `--bg-deep` at corners; subtle 2% noise for texture is OK.

## Motion identity

- Everything snaps on strong eases (`power3.out`, `expo.out`).
- Slash arcs stroke-draw in 120–180ms.
- Screen shake lives on the root scene group, not individual sprites —
  2–4px amplitude, 180ms burst — matches `camera_shake.gd`.
- Nothing crossfades over 300ms in the combat section; cuts over fades.
- Hook and CTA may use longer eases (400–600ms) for breathing room.

## What NOT to introduce

- No stock stock-photo gradients, no neon glow, no 3D depth cues.
- No invented UI chrome (no fake HUD bars, no fake joystick) — the game
  has a virtual joystick in `touch_controls.tscn` but it stays off-trailer.
- No voiceover. Beat text + BGM carry the narrative.
