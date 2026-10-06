# Local build helpers for Samurai (Godot 4.3).
#
#   make build   Export a Windows debug build to build/windows/
#   make run     Build, then launch with the debug console attached
#   make clean   Delete build/windows/
#
# Expects the Godot editor in tools/godot/ (gitignored). Override with
#   make build GODOT=path/to/godot

GODOT_VERSION := 4.3
PRESET        := Windows Desktop
OUT_DIR       := build/windows
OUT_EXE       := $(OUT_DIR)/samurai.exe

ifeq ($(OS),Windows_NT)
  # Force cmd.exe so recipes behave the same from PowerShell, cmd, or Git Bash.
  SHELL   := cmd.exe
  GODOT   ?= tools\godot\Godot_v$(GODOT_VERSION)-stable_win64_console.exe
  WIN_DIR := $(subst /,\,$(OUT_DIR))
  MKDIR   := if not exist "$(WIN_DIR)" mkdir "$(WIN_DIR)"
  RMDIR   := if exist "$(WIN_DIR)" rmdir /s /q "$(WIN_DIR)"
  RUN_EXE := "$(WIN_DIR)\samurai.console.exe"
else
  GODOT   ?= godot
  MKDIR   := mkdir -p "$(OUT_DIR)"
  RMDIR   := rm -rf "$(OUT_DIR)"
  RUN_EXE := "./$(OUT_DIR)/samurai.console.exe"
endif

.PHONY: build run clean

build:
	$(MKDIR)
	"$(GODOT)" --headless --path . --import
	"$(GODOT)" --headless --path . --export-debug "$(PRESET)" "$(OUT_EXE)"

run: build
	$(RUN_EXE)

clean:
	$(RMDIR)
