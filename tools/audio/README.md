# Audio generators

The sound effects and music in `assets/audio/` are original, synthesized
chiptune-style audio made by these scripts. Nothing is sampled from the
Pokémon games or anime, and the two melodies are original compositions.

```bash
pip install numpy scipy
python3 tools/audio/generate_sfx.py     # writes assets/audio/sfx/*.wav
python3 tools/audio/generate_music.py   # writes assets/audio/music/*.wav
```

Edit a note, envelope or tempo in the script and re-run it to change a sound.
`generate_sfx.py` lists every effect with a one-line comment; names match the
`Sfx` enum in `lib/services/audio_service.dart`. The music loops are seamless
(the reverb tail is folded back onto the start).
