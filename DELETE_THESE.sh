#!/usr/bin/env bash
# Run from the repository root AFTER copying the corrected files over it.
# Untracks and removes files that are no longer needed. Review before running.
set -e
git rm -r --cached --ignore-unmatch .dart_tool build .flutter-plugins-dependencies tools/.import_progress.json
rm -rf .dart_tool build .flutter-plugins-dependencies tools/.import_progress.json
git rm -f --ignore-unmatch assets/audio/music/bgm_main.wav assets/audio/music/bgm_title.wav
rm -f assets/audio/music/bgm_main.wav assets/audio/music/bgm_title.wav
git rm -f --ignore-unmatch START-HERE.md
rm -f START-HERE.md
