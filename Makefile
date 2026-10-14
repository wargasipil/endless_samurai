# Samurai dev shortcuts
#
# Usage from the project root:
#   make run       — launch main scene (skips title, fastest preview)
#   make play      — launch the game from the title screen (end-user flow)
#   make editor    — open the Godot editor (for breakpoints, scene edits, debugger)
#   make demo      — run with --demo autopilot (no screen capture)
#   make import    — headless re-import of all assets
#   make check     — import + script parse pass, prints errors only
#   make record    — record 45s raw vertical AVI (1280x2275) via --write-movie + --demo
#   make mp4       — convert raw AVI to 30s vertical 1080x1920 MP4
#   make hook      — mp4 with 1.6s "ENDLESS SAMURAI" hook card prepended
#   make tiktok    — record + mp4 + hook (full pipeline)
#   make clean-cache  — delete the .godot import cache (safe)
#   make clean-render — delete raw AVIs and MP4 outputs under videos/
#
# Flags:
#   V=1               verbose Godot output
#   DURATION=600      --quit-after frames for `make record` (default 2700 = 45s @60fps)
#   OFFSET=2          start seconds inside the raw AVI for `make mp4` (default 2)

GODOT ?= tools/godot/Godot_v4.3-stable_win64_console.exe
PROJECT := .
SCENE_MAIN := res://scenes/main.tscn
SCENE_TITLE := res://scenes/title.tscn
SCENE_HP := res://scenes/healthbar_preview.tscn
SCENE_DPAD := res://scenes/dpad_preview.tscn
VIDEO_DIR := videos/tiktok-gameplay-30s
RAW := $(VIDEO_DIR)/gameplay-raw.avi
MP4 := $(VIDEO_DIR)/samurai-tiktok-30s.mp4
HOOK_MP4 := $(VIDEO_DIR)/samurai-tiktok-hook.mp4

DURATION ?= 2700
OFFSET ?= 2
VERBOSE := $(if $(V),--verbose,)
FFMPEG ?= ffmpeg
FONT := C\\:/Windows/Fonts/impact.ttf

.PHONY: help run play editor demo hp dpad import check record mp4 hook tiktok clean-cache clean-render

help:
	@echo "Targets: run play editor demo import check record mp4 hook tiktok clean-cache clean-render"
	@echo "See Makefile for flags (V=1, DURATION=, OFFSET=)."

run:
	"$(GODOT)" --path "$(PROJECT)" $(VERBOSE) "$(SCENE_MAIN)"

play:
	"$(GODOT)" --path "$(PROJECT)" $(VERBOSE)

editor:
	"$(GODOT)" --path "$(PROJECT)" --editor

demo:
	"$(GODOT)" --path "$(PROJECT)" $(VERBOSE) "$(SCENE_MAIN)" -- --demo

hp:
	"$(GODOT)" --path "$(PROJECT)" $(VERBOSE) "$(SCENE_HP)"

dpad:
	"$(GODOT)" --path "$(PROJECT)" $(VERBOSE) "$(SCENE_DPAD)"

import:
	"$(GODOT)" --path "$(PROJECT)" --headless --import

check:
	"$(GODOT)" --path "$(PROJECT)" --headless --import 2>&1 | grep -E "ERROR|SCRIPT ERROR|WARNING" || echo "OK: no errors"

# Vertical capture: the screen can't hold a 1920 px tall window, so a temporary override.cfg
# switches to "viewport" stretch with a small window; Godot then renders and records the
# base 1280x720 expanded to the window's 9:16 (1280x2275), the same view a portrait phone gets.
record:
	@mkdir -p "$(VIDEO_DIR)"
	@printf '[display]\n\nwindow/size/window_width_override=540\nwindow/size/window_height_override=960\nwindow/stretch/mode="viewport"\n' > override.cfg
	"$(GODOT)" --path "$(PROJECT)" --write-movie "$(RAW)" --fixed-fps 60 --quit-after $(DURATION) -- --demo; \
	  status=$$?; rm -f override.cfg; exit $$status
	@echo ""
	@echo "Raw AVI: $(RAW)"

mp4: $(RAW)
	$(FFMPEG) -ss $(OFFSET) -i "$(RAW)" -t 30 \
	  -vf "scale=1080:1920:flags=lanczos,setsar=1,fade=t=in:st=0:d=0.3,fade=t=out:st=29.6:d=0.4" \
	  -c:v libx264 -preset slow -crf 19 -pix_fmt yuv420p -movflags +faststart -an \
	  -y "$(MP4)"
	@echo ""
	@echo "MP4: $(MP4)"

hook: $(MP4)
	$(FFMPEG) \
	  -f lavfi -i color=c=0x0A0612:s=1080x1920:d=1.6:r=60 \
	  -i "$(MP4)" \
	  -filter_complex "\
	    [0:v]drawtext=fontfile='$(FONT)':text='ENDLESS':fontcolor=0xF5EBD1:fontsize=220:x=(w-text_w)/2:y=(h-text_h)/2-180:alpha='if(lt(t\,0.25)\,t/0.25\,if(gt(t\,1.35)\,max(0\,(1.6-t)/0.25)\,1))',\
	    drawtext=fontfile='$(FONT)':text='SAMURAI':fontcolor=0xF5EBD1:fontsize=220:x=(w-text_w)/2:y=(h-text_h)/2+40:alpha='if(lt(t\,0.5)\,max(0\,(t-0.25)/0.25)\,if(gt(t\,1.35)\,max(0\,(1.6-t)/0.25)\,1))',\
	    format=yuv420p,setsar=1[title];\
	    [1:v]setsar=1,format=yuv420p[gp];[title][gp]concat=n=2:v=1:a=0[out]" \
	  -map "[out]" -c:v libx264 -preset slow -crf 19 -pix_fmt yuv420p -movflags +faststart -an \
	  -y "$(HOOK_MP4)"
	@echo ""
	@echo "Hooked MP4: $(HOOK_MP4)"

tiktok: record mp4 hook

$(RAW):
	@echo "Raw AVI missing. Run: make record" >&2
	@exit 1

clean-cache:
	rm -rf .godot

clean-render:
	rm -f $(RAW) $(MP4) $(HOOK_MP4)
