# Audio generators

The sound effects in `assets/audio/sfx/` are original, synthesized
chiptune-style audio made by these scripts. Nothing is sampled from the
Pokémon games or anime.

```bash
pip install numpy scipy
python3 tools/audio/generate_sfx.py     # writes assets/audio/sfx/*.wav (25 files)
```

Edit a note, envelope or tempo in the script and re-run it to change a sound.
`generate_sfx.py` lists every effect with a one-line comment; names match the
`Sfx` enum in `lib/services/audio_service.dart`. The `scan`, `scan_found` and
`scan_none` effects keep their names from the removed card scanner and now play
for catalog search.

## Music

The two background tracks the app plays are `assets/audio/music/bgm_title.mp3`
and `bgm_main.mp3` (the `MusicTrack` enum in `audio_service.dart`). They are
**not** produced by these scripts: they come from Pokémon HOME and are credited
in the main [README](../../README.md#credits) but not licensed.

`generate_music.py` is an earlier synthesized version. It writes
`bgm_main.wav` and `bgm_title.wav` into `assets/audio/music/`, which the app
does not load. To use original music, generate the `.wav` files, convert them to
`.mp3` (or change the paths in `MusicTrack`), and update the credits.
