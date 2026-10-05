import os, numpy as np
from synth_lib import *

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'audio', 'music')
os.makedirs(OUT, exist_ok=True)
MSR = 22050

def parse(seq):
    """'E5:.5 G5:.5 R:1' -> [(note|None, beats)]"""
    out = []
    for tok in seq.split():
        n, d = tok.split(':')
        out.append((None if n == 'R' else n, float(d)))
    return out

def render(bpm, bars, lead, chords, lead_vol=0.30, arp_vol=0.11, bass_vol=0.34, hat=True,
           kick_from=None, pad_vol=0.07, swing=0.0):
    beat = 60.0 / bpm
    total = bars * 4 * beat
    tail = 2.0
    B = np.zeros(int((total + tail) * HR))
    # lead (25% pulse, slight vibrato on long notes)
    t = 0.0
    for n, d in lead:
        if n:
            dur = d * beat
            long_ = d >= 1.5
            sig = blip(hz(n), dur * 0.97 + 0.05, 'pulse', 0.25, a=0.006, d=0.12, s=0.62,
                       r=0.06 + 0.03 * long_, vib=0.006 if long_ else 0.0, vibhz=5.5)
            place(B, sig, t * beat, lead_vol)
        t += d
    # chords: bass (triangle), arpeggio (12.5% pulse), pad (soft triangle)
    for bar, (bass, tones) in enumerate(chords):
        b0 = bar * 4 * beat
        # bass: root on 1, fifth-ish on 3, walking pickup on 4&
        place(B, blip(hz(bass), beat * 1.9, 'tri', a=0.004, d=0.15, s=0.75, r=0.08), b0, bass_vol)
        place(B, blip(hz(tones[2][:-1] + '3') if False else hz(bass) * 1.5, beat * 1.4, 'tri', a=0.004, d=0.12, s=0.7, r=0.08), b0 + 2*beat, bass_vol * 0.85)
        place(B, blip(hz(bass) * 2, beat * 0.45, 'tri', a=0.003, d=0.08, s=0.5, r=0.05), b0 + 3.5*beat, bass_vol * 0.6)
        # arpeggio, eighth notes: root-3rd-5th-oct-5th-3rd-5th-3rd (one octave above C4 range)
        order = [0, 1, 2, 3, 2, 1, 2, 1]
        for k, idx in enumerate(order):
            f = hz(tones[idx])
            place(B, blip(f, beat * 0.5, 'pulse', 0.125, a=0.003, d=0.06, s=0.35, r=0.05), b0 + k * 0.5 * beat, arp_vol)
        # pad
        for tn in tones[:3]:
            place(B, blip(hz(tn) / 2, beat * 3.9, 'tri', a=0.12, d=0.4, s=0.8, r=0.3), b0, pad_vol * 0.5)
        # soft hats on offbeats; light kick on 1 and 3 in the second half
        if hat:
            for k in range(8):
                if k % 2 == 1:
                    n_ = int(0.035 * HR)
                    h = hp(noise(n_, 100 + bar*8 + k), 6000) * env(n_, 0.0005, 0.02, 0.1, 0.01)
                    place(B, h, b0 + k * 0.5 * beat, 0.05)
        if kick_from is not None and bar >= kick_from:
            for kb in (0, 2):
                k_ = blip(120, 0.14, 'sine', f1=48, a=0.001, d=0.08, s=0.15, r=0.05)
                place(B, k_, b0 + kb * beat, 0.16)
    # warm echo and fold the tail back so the loop is seamless
    B = echo(B, HR, beat * 0.75, 0.28, 3, 0.8)
    n = int(total * HR)
    B[:len(B) - n] += 0  # no-op for clarity
    tailpart = B[n:]
    B = B[:n].copy()
    B[:len(tailpart)] += tailpart[:n]
    B = lp(B, 7500, 2)
    y = downsample(B, 2 * OS)  # HR -> 22.05k (44100*4/8)
    y = y / np.max(np.abs(y)) * 0.8
    return y

# ----------------------------- MAIN THEME (C major, 100 bpm) -----------------
main_lead = parse("""
E5:.5 G5:.5 C6:1 B5:.5 G5:.5 E5:1
D5:1 G5:1 B5:1 A5:.5 G5:.5
C5:.5 E5:.5 A5:1 G5:.5 E5:.5 C5:1
B4:1 E5:1 G5:1.5 F#5:.5
A5:1 C6:1 A5:.5 G5:.5 F5:1
G5:1 E5:.5 G5:.5 C6:2
F5:.5 A5:.5 D6:1 C6:.5 A5:.5 F5:1
G5:1 B5:1 D6:1 B5:1
C6:1 A5:.5 F5:.5 A5:1 C6:1
B5:1 G5:.5 D5:.5 G5:1 B5:1
G5:.5 B5:.5 E6:1 D6:.5 B5:.5 G5:1
A5:1 C6:1 E6:1 C6:1
A5:.5 C6:.5 F6:1 E6:.5 C6:.5 A5:1
B5:.5 D6:.5 G6:1 F6:.5 D6:.5 B5:1
E6:1.5 D6:.5 C6:1 G5:1
D6:1 B5:1 G5:2
""")
main_chords = [
    ('C3', ['C4', 'E4', 'G4', 'C5']),
    ('B2', ['D4', 'G4', 'B4', 'D5']),
    ('A2', ['C4', 'E4', 'A4', 'C5']),
    ('E3', ['B3', 'E4', 'G4', 'B4']),
    ('F3', ['C4', 'F4', 'A4', 'C5']),
    ('E3', ['C4', 'E4', 'G4', 'C5']),
    ('D3', ['D4', 'F4', 'A4', 'C5']),
    ('G3', ['D4', 'G4', 'B4', 'D5']),
    ('F3', ['C4', 'F4', 'A4', 'C5']),
    ('G3', ['D4', 'G4', 'B4', 'D5']),
    ('E3', ['B3', 'E4', 'G4', 'B4']),
    ('A2', ['C4', 'E4', 'A4', 'C5']),
    ('F3', ['C4', 'F4', 'A4', 'C5']),
    ('G3', ['D4', 'G4', 'B4', 'D5']),
    ('C3', ['C4', 'E4', 'G4', 'C5']),
    ('G3', ['D4', 'G4', 'B4', 'D5']),
]
y = render(100, 16, main_lead, main_chords, kick_from=8)
save(f'{OUT}/bgm_main.wav', y, MSR)
print('main', len(y) / MSR, 's')

# ----------------------------- TITLE THEME (G major, 88 bpm) -----------------
title_lead = parse("""
D5:1 G5:1 B5:1.5 A5:.5
A5:1 F#5:1 D5:1 F#5:1
G5:1 E5:.5 G5:.5 B5:1 E6:1
D6:1.5 B5:.5 F#5:1 B5:1
E5:.5 G5:.5 C6:1 E6:1 D6:.5 C6:.5
B5:1 D6:1 G6:1.5 D6:.5
C6:1 E6:1 D6:.5 C6:.5 A5:1
F#5:1 A5:1 D6:2
E6:1 C6:1 G5:1 C6:1
D6:1 A5:1 F#5:1 A5:1
B5:1 D6:1 F#6:1 D6:1
E6:1.5 D6:.5 B5:1 G5:1
C6:.5 E6:.5 G6:1 E6:.5 C6:.5 E6:1
D6:.5 F#6:.5 A6:1 F#6:.5 D6:.5 A5:1
B5:1 D6:1 G6:2
A5:1 B5:1 A5:1 F#5:1
""")
title_chords = [
    ('G3', ['G3', 'B3', 'D4', 'G4']),
    ('F#3', ['A3', 'D4', 'F#4', 'A4']),
    ('E3', ['G3', 'B3', 'E4', 'G4']),
    ('B2', ['B3', 'D4', 'F#4', 'B4']),
    ('C3', ['C4', 'E4', 'G4', 'C5']),
    ('B2', ['D4', 'G4', 'B4', 'D5']),
    ('A2', ['C4', 'E4', 'G4', 'A4']),
    ('D3', ['D4', 'F#4', 'A4', 'D5']),
    ('C3', ['C4', 'E4', 'G4', 'C5']),
    ('D3', ['D4', 'F#4', 'A4', 'D5']),
    ('B2', ['B3', 'D4', 'F#4', 'B4']),
    ('E3', ['G3', 'B3', 'E4', 'G4']),
    ('C3', ['C4', 'E4', 'G4', 'C5']),
    ('D3', ['D4', 'F#4', 'A4', 'D5']),
    ('G3', ['G3', 'B3', 'D4', 'G4']),
    ('D3', ['D4', 'F#4', 'A4', 'D5']),
]
y = render(88, 16, title_lead, title_chords, lead_vol=0.28, arp_vol=0.12, pad_vol=0.1, kick_from=None)
save(f'{OUT}/bgm_title.wav', y, MSR)
print('title', len(y) / MSR, 's')
