# tiktok-gameplay-30s — screen-captured gameplay TikTok

Live gameplay recording of the Samurai game, cropped to vertical 1080x1920
for TikTok. Companion to `videos/tiktok-preview-30s/` (stylized SVG recreation).

## 1. Install Godot 4.3 (Mobile, Windows x64)

Portable, no admin needed. Preferred location per project convention:

```
D:\wargasipil\samurai\tools\godot\Godot_v4.3-stable_win64.exe
```

Download link: https://godotengine.org/download/archive/4.3-stable/
Pick **Godot Engine 4.3 Standard — Windows (64-bit)** and unzip the exe into
`tools/godot/`. The whole `tools/` tree is gitignored.

## 2. Record raw gameplay (one command, no manual play)

The game ships with a `--demo` autopilot that pilots the samurai, chases
nearest enemies, swings on contact, and jumps on bunches. Combined with
Godot's built-in `--write-movie` deterministic recorder, this gives a
hands-off capture:

```powershell
D:\wargasipil\samurai\tools\godot\Godot_v4.3-stable_win64.exe `
  --path D:\wargasipil\samurai `
  --write-movie D:\wargasipil\samurai\videos\tiktok-gameplay-30s\gameplay-raw.avi `
  --fixed-fps 60 `
  --quit-after 2700 `
  -- --demo
```

- `--fixed-fps 60` locks the physics step to 60Hz for deterministic frame output.
- `--quit-after 2700` exits after 2700 frames = **45s** of footage (gives cut room for a 30s final).
- The `--demo` after the bare `--` is passed to the game, where `scripts/demo_controller.gd` picks it up and hides the on-screen touch controls.

Output: `gameplay-raw.avi` (landscape 1280x720, no audio, uncompressed-ish).

## 3. Hand it off

Once the AVI exists, point Claude at it. It gets:

- cropped to vertical 1080x1920 (center crop or zoomed reframe)
- cut to a 30s highlight with punch-ins on hits
- re-encoded H.264 + optional BGM/CTA overlay inside a HyperFrames composition

## Notes

- `--demo` also skips the title screen (see `scripts/title.gd`).
- To preview the demo autopilot interactively (watch it play) just run the game normally and pass `--demo` on the Godot command line without `--write-movie`.
- Raw AVIs, renders, and `node_modules/` are gitignored (`videos/*/renders/`, `*.mp4`, etc.) — raw AVIs stay out via `*.avi` too (added below).
