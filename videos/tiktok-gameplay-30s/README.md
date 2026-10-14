# tiktok-gameplay-30s — screen-captured gameplay TikTok

Live gameplay recording of the Samurai game in the origami arena, captured vertical
(1080x1920) for TikTok. Companion to `videos/tiktok-preview-30s/` (stylized SVG recreation).

## 1. Install Godot 4.3 (Mobile, Windows x64)

Portable, no admin needed. Put it in `tools/godot/` (the whole `tools/` tree is gitignored):

```
tools/godot/Godot_v4.3-stable_win64.exe
tools/godot/Godot_v4.3-stable_win64_console.exe
```

Download link: https://godotengine.org/download/archive/4.3-stable/
Pick **Godot Engine 4.3 Standard — Windows (64-bit)**.

## 2. Record and encode (one command each, no manual play)

```bash
make record DURATION=3000   # 50 s raw AVI, vertical 1280x2275 at 60 fps, the --demo autopilot playing
make mp4 OFFSET=17          # 30 s from 17 s in (wave 2 brings the wraiths at 20 s, wave 3 the big skeletons at 40 s),
                            # scaled to 1080x1920, H.264 -> samurai-tiktok-30s.mp4 (the 2026-10-14 cut)
make hook          # optional: prepends the 1.6 s "ENDLESS SAMURAI" title card
```

- The game runs in `--demo`: `scripts/demo_controller.gd` pilots the samurai (chases the
  nearest enemy near the courtyard, walks back to it otherwise, steers round stones and
  trees, swings on contact, jumps on bunches), hides the touch controls and gives him 20 HP.
  About 48 s in he is nearly out of HP, so longer runs end in a game over.
- Characters: the player is the library Samurai, grunts are Skeletons, runners Wraiths,
  brutes big Skeletons (`assets/characters/*.glb`, from the Blender project:
  `run.ps1 game-characters`).
- `--write-movie` with `--fixed-fps 60` records every frame deterministically (it runs at
  ~25 % of real time while recording, about 3 minutes for 45 s).
- **Why 1280x2275:** a 1920 px tall window doesn't fit a 1080p screen (Windows clamps it), so
  `make record` writes a temporary `override.cfg` that switches the stretch mode to
  `viewport` with a 540x960 window. Godot then renders and records the base 1280x720
  expanded to 9:16, the same view (and HUD layout) a portrait phone gets. The file is
  deleted afterwards and is gitignored in case a run is interrupted.
- On portrait screens `scripts/main.gd` frames the camera by width (higher and wider) so
  the arena around the samurai stays in view.

Outputs (gitignored): `gameplay-raw.avi` (~680 MB), `samurai-tiktok-30s.mp4` (~80 MB),
`samurai-tiktok-hook.mp4`.

## Notes

- `--demo` also skips the title screen (see `scripts/title.gd`).
- To watch the autopilot play, run `make demo`.
- The arena itself comes from the Blender project (`D:\blender_project`, place
  SamuraiArena); see the header of `scripts/arena.gd`.
