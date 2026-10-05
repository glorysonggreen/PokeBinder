import os, numpy as np
from synth_lib import *

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', '..', 'assets', 'audio', 'sfx')
os.makedirs(OUT, exist_ok=True)
S = {}

def buf(d): return np.zeros(int(d * HR))

# --- UI basics -------------------------------------------------------------
# tap: tiny menu blip
x = blip(1568, 0.045, 'pulse', 0.25, f1=1760, a=0.001, d=0.02, s=0.4, r=0.015)
S['tap'] = (x, 0.55)

# add_press: Poké-Ball "ready" ping, rising 3-note
b = buf(0.32)
for i, n in enumerate(['G5', 'C6', 'E6']):
    place(b, blip(hz(n), 0.1, 'pulse', 0.25, a=0.002, d=0.05, s=0.4, r=0.05), i * 0.06)
place(b, blip(hz('G6'), 0.16, 'tri', f1=hz('G6')*1.01, a=0.002, d=0.1, s=0.3, r=0.1), 0.18, 0.7)
S['add_press'] = (b, 0.8)

# page_in / page_out: paper swish
def swish(dur, up=True, vol=1.0):
    n = int(dur * HR); t = np.arange(n) / HR
    nz = noise(n, 3)
    sweep = np.linspace(1200, 4200, n) if up else np.linspace(4200, 1200, n)
    # moving band via modulated high-pass approximation: filter chunks
    out = np.zeros(n); chunk = n // 12
    for i in range(12):
        c = sweep[min(i * chunk, n-1)]
        seg = nz[i*chunk:(i+1)*chunk if i < 11 else n]
        out[i*chunk:i*chunk+len(seg)] = bp(seg, max(c*0.6, 300), min(c*1.4, 9000), 2)
    e = np.sin(np.pi * np.linspace(0, 1, n)) ** 1.5
    return out * e * vol
b = buf(0.2); place(b, swish(0.17, True), 0.0); place(b, blip(hz('E5'), 0.04, 'tri', a=0.001, d=0.02, s=0.3, r=0.02), 0.14, 0.25)
S['page_in'] = (b, 0.35)
b = buf(0.18); place(b, swish(0.15, False), 0.0)
S['page_out'] = (b, 0.3)

# dialog: little "question" two-note pop
b = buf(0.2)
place(b, blip(hz('D6'), 0.07, 'pulse', 0.5, a=0.002, d=0.03, s=0.4, r=0.03), 0.0)
place(b, blip(hz('A6'), 0.09, 'pulse', 0.5, a=0.002, d=0.04, s=0.4, r=0.05), 0.065)
S['dialog'] = (b, 0.5)

# --- Cards ------------------------------------------------------------------
# card_select: snap + glint
b = buf(0.16)
place(b, hp(noise(int(0.02*HR), 5), 2500) * env(int(0.02*HR), 0.0005, 0.01, 0.2, 0.008), 0.0, 0.8)
place(b, blip(hz('B6'), 0.08, 'tri', a=0.001, d=0.05, s=0.2, r=0.04), 0.012, 0.5)
S['card_select'] = (b, 0.55)

# card_deal: slide swish then soft thud on the table
b = buf(0.38)
place(b, swish(0.22, False), 0.0, 0.9)
th = blip(150, 0.12, 'sine', f1=60, a=0.001, d=0.08, s=0.1, r=0.06)
place(b, th, 0.2, 0.9)
place(b, lp(noise(int(0.05*HR), 8), 1500) * env(int(0.05*HR), 0.001, 0.03, 0.1, 0.02), 0.2, 0.35)
S['card_deal'] = (b, 0.7)

# card_add: slide in + bright 3-note success chime
b = buf(0.8)
place(b, swish(0.14, True), 0.0, 0.6)
for i, n in enumerate(['C6', 'E6', 'G6']):
    place(b, blip(hz(n), 0.22, 'pulse', 0.25, a=0.002, d=0.1, s=0.35, r=0.12), 0.12 + i*0.075, 0.7)
place(b, blip(hz('C7'), 0.4, 'tri', a=0.002, d=0.2, s=0.3, r=0.25, vib=0.004), 0.35, 0.55)
S['card_add'] = (echo(b, HR, 0.11, 0.3, 2), 0.85)

# card_move: card slotted into a sleeve: swish + tiny click
b = buf(0.3)
place(b, swish(0.12, True), 0.0, 0.7)
place(b, blip(hz('G5'), 0.05, 'pulse', 0.25, a=0.001, d=0.03, s=0.3, r=0.02), 0.11, 0.7)
place(b, blip(hz('C6'), 0.07, 'pulse', 0.25, a=0.001, d=0.04, s=0.3, r=0.03), 0.15, 0.7)
S['card_move'] = (b, 0.6)

# card_zoom / card_close: card lifted up to view / put back
b = buf(0.33)
place(b, blip(hz('C5'), 0.22, 'sine', f1=hz('C6'), a=0.01, d=0.12, s=0.3, r=0.1), 0.0, 0.5)
place(b, swish(0.2, True), 0.0, 0.5)
place(b, blip(hz('G6'), 0.1, 'tri', a=0.002, d=0.06, s=0.2, r=0.06), 0.2, 0.4)
S['card_zoom'] = (b, 0.6)
b = buf(0.26)
place(b, blip(hz('C6'), 0.18, 'sine', f1=hz('C5'), a=0.005, d=0.1, s=0.3, r=0.08), 0.0, 0.5)
place(b, swish(0.16, False), 0.0, 0.5)
S['card_close'] = (b, 0.5)

# foil: holographic shimmer when you tilt a card
b = buf(0.5)
for i, n in enumerate(['E7', 'G7', 'B6', 'D7', 'A7']):
    place(b, blip(hz(n), 0.18, 'sine', a=0.003, d=0.1, s=0.2, r=0.1, vib=0.01, vibhz=14), i*0.055, 0.5 - i*0.05)
S['foil'] = (echo(b, HR, 0.08, 0.35, 3), 0.4)

# rare: sparkle fanfare for high-rarity cards
b = buf(1.1)
seq = ['E6', 'G6', 'C7', 'E7', 'G7', 'C8']
for i, n in enumerate(seq):
    place(b, blip(hz(n), 0.3, 'tri', a=0.002, d=0.15, s=0.25, r=0.2), i*0.06, 0.8 - i*0.06)
place(b, blip(hz('C7'), 0.6, 'pulse', 0.125, a=0.004, d=0.3, s=0.25, r=0.3, vib=0.006), 0.36, 0.45)
place(b, blip(hz('E7'), 0.6, 'pulse', 0.125, a=0.004, d=0.3, s=0.25, r=0.3, vib=0.006), 0.36, 0.35)
S['rare'] = (echo(b, HR, 0.13, 0.35, 4), 0.8)

# --- Scanning (catalog search) ----------------------------------------------
# scan: rising radar sweep with soft pulses
b = buf(0.5)
place(b, blip(500, 0.45, 'sine', f1=1800, a=0.02, d=0.2, s=0.5, r=0.15, vib=0.03, vibhz=18), 0.0, 0.6)
place(b, blip(1000, 0.45, 'tri', f1=3600, a=0.02, d=0.2, s=0.3, r=0.15), 0.0, 0.25)
S['scan'] = (b, 0.45)
# scan_found: two bright dings
b = buf(0.45)
place(b, blip(hz('E6'), 0.14, 'pulse', 0.25, a=0.002, d=0.07, s=0.4, r=0.06), 0.0)
place(b, blip(hz('B6'), 0.28, 'pulse', 0.25, a=0.002, d=0.12, s=0.35, r=0.15), 0.11)
S['scan_found'] = (echo(b, HR, 0.09, 0.3, 2), 0.7)
# scan_none: soft descending "nothing here"
b = buf(0.35)
place(b, blip(hz('A5'), 0.12, 'tri', a=0.003, d=0.06, s=0.4, r=0.05), 0.0)
place(b, blip(hz('E5'), 0.2, 'tri', a=0.003, d=0.1, s=0.3, r=0.1), 0.1)
S['scan_none'] = (b, 0.55)

# --- Feedback ---------------------------------------------------------------
# success: happy ascending jingle
b = buf(0.95)
for i, (n, d) in enumerate([('C6', .1), ('E6', .1), ('G6', .1), ('C7', .45)]):
    place(b, blip(hz(n), d + 0.12, 'pulse', 0.25, a=0.002, d=0.08, s=0.45, r=0.1 if i < 3 else 0.3), [0, .09, .18, .27][i])
place(b, blip(hz('E6'), 0.5, 'pulse', 0.125, a=0.002, d=0.2, s=0.3, r=0.25), 0.27, 0.5)
place(b, blip(hz('G6'), 0.5, 'pulse', 0.125, a=0.002, d=0.2, s=0.3, r=0.25), 0.27, 0.4)
S['success'] = (echo(b, HR, 0.12, 0.28, 3), 0.85)

# error: low buzzy double-tone
b = buf(0.4)
place(b, blip(hz('E3'), 0.14, 'pulse', 0.5, f1=hz('D3'), a=0.002, d=0.05, s=0.7, r=0.03), 0.0)
place(b, blip(hz('Bb2'), 0.2, 'pulse', 0.5, f1=hz('G2'), a=0.002, d=0.08, s=0.7, r=0.08), 0.15)
S['error'] = (lp(b, 3500), 0.7)

# remove: descending crunch
b = buf(0.35)
place(b, blip(hz('E5'), 0.28, 'pulse', 0.5, f1=hz('E3'), a=0.002, d=0.12, s=0.4, r=0.12), 0.0, 0.7)
nz = lp(noise(int(0.12*HR), 11), 3000) * env(int(0.12*HR), 0.001, 0.06, 0.15, 0.05)
place(b, nz, 0.0, 0.5)
S['remove'] = (b, 0.7)

# save: gentle confirm tick-tock
b = buf(0.3)
place(b, blip(hz('G5'), 0.08, 'pulse', 0.25, a=0.002, d=0.04, s=0.4, r=0.04), 0.0)
place(b, blip(hz('D6'), 0.16, 'pulse', 0.25, a=0.002, d=0.07, s=0.4, r=0.09), 0.08)
S['save'] = (echo(b, HR, 0.08, 0.25, 2), 0.65)

# toggles
b = buf(0.18); place(b, blip(hz('C6'), 0.06, 'pulse', 0.25, a=0.001, d=0.03, s=0.4, r=0.03), 0.0); place(b, blip(hz('G6'), 0.09, 'pulse', 0.25, a=0.001, d=0.04, s=0.4, r=0.05), 0.05)
S['toggle_on'] = (b, 0.6)
b = buf(0.18); place(b, blip(hz('G6'), 0.06, 'pulse', 0.25, a=0.001, d=0.03, s=0.4, r=0.03), 0.0); place(b, blip(hz('C6'), 0.09, 'pulse', 0.25, a=0.001, d=0.04, s=0.4, r=0.05), 0.05)
S['toggle_off'] = (b, 0.6)

# star: wishlist / favourite sparkle
b = buf(0.5)
for i, n in enumerate(['A6', 'E7', 'A7']):
    place(b, blip(hz(n), 0.22, 'tri', a=0.002, d=0.1, s=0.3, r=0.12), i*0.07, 0.8)
S['star'] = (echo(b, HR, 0.1, 0.35, 3), 0.7)

# sign_out: Poké Ball closing, two descending notes + click
b = buf(0.55)
place(b, blip(hz('G5'), 0.15, 'pulse', 0.25, a=0.002, d=0.07, s=0.4, r=0.07), 0.0)
place(b, blip(hz('C5'), 0.3, 'pulse', 0.25, a=0.002, d=0.12, s=0.4, r=0.18), 0.13)
place(b, blip(hz('C4'), 0.04, 'pulse', 0.5, a=0.001, d=0.02, s=0.3, r=0.02), 0.42, 0.7)
S['sign_out'] = (b, 0.65)

# --- Intro (timed to PokeBinderIntro's 2.6 s timeline) -----------------------
D = 2.7
b = buf(D)
# 0-450ms ball drops, bounceOut: ground hits at ~164, 327, 409, 450 ms
for tm, v, f in [(0.164, 1.0, 130), (0.327, 0.6, 150), (0.409, 0.35, 170), (0.448, 0.18, 190)]:
    place(b, blip(f, 0.1, 'sine', f1=f*0.45, a=0.001, d=0.06, s=0.1, r=0.04), tm, v)
    place(b, lp(noise(int(0.04*HR), int(tm*1000)), 2000) * env(int(0.04*HR), 0.001, 0.02, 0.1, 0.015), tm, v*0.4)
# 675 / 850 / 1025 ms wobble clicks (direction changes), getting softer
for tm, v in [(0.675, 0.8), (0.85, 0.6), (1.025, 0.4)]:
    place(b, blip(hz('C6'), 0.05, 'pulse', 0.25, a=0.001, d=0.03, s=0.3, r=0.02), tm, v)
    place(b, blip(hz('G5'), 0.05, 'pulse', 0.25, a=0.001, d=0.03, s=0.3, r=0.02), tm + 0.02, v*0.7)
# 1200-1380 glow rise
place(b, blip(300, 0.2, 'sine', f1=1500, a=0.02, d=0.1, s=0.6, r=0.05), 1.2, 0.55)
place(b, blip(600, 0.2, 'tri', f1=3000, a=0.02, d=0.1, s=0.4, r=0.05), 1.2, 0.25)
# 1380 burst open: pop + shimmer + fanfare chord
place(b, lp(noise(int(0.25*HR), 21), 5000) * env(int(0.25*HR), 0.001, 0.12, 0.15, 0.1), 1.38, 0.5)
place(b, blip(220, 0.12, 'sine', f1=70, a=0.001, d=0.08, s=0.1, r=0.05), 1.38, 0.8)
for i, n in enumerate(['C7', 'E7', 'G7', 'B7', 'E8', 'G7', 'D8', 'C8']):
    place(b, blip(hz(n), 0.28, 'sine', a=0.002, d=0.12, s=0.2, r=0.15, vib=0.008, vibhz=12), 1.4 + i*0.07, 0.35)
# wordmark fanfare "ta-da-da-DAA" 1.52 onward
fan = [('G5', 1.52, .12), ('C6', 1.64, .12), ('E6', 1.76, .12), ('G6', 1.88, .55)]
for n, at, d in fan:
    place(b, blip(hz(n), d + 0.15, 'pulse', 0.25, a=0.002, d=0.08, s=0.5, r=0.2 if d > .2 else 0.06), at, 0.75)
for n in ['C5', 'E5']:
    place(b, blip(hz(n), 0.8, 'pulse', 0.125, a=0.004, d=0.3, s=0.4, r=0.4), 1.88, 0.35)
place(b, blip(hz('C4'), 0.9, 'tri', a=0.004, d=0.4, s=0.6, r=0.45), 1.88, 0.6)
place(b, blip(hz('C7'), 0.7, 'tri', a=0.004, d=0.3, s=0.3, r=0.4, vib=0.005), 1.95, 0.4)
# 1950-2500 foil shine glide
place(b, blip(hz('E7'), 0.5, 'sine', f1=hz('E8'), a=0.05, d=0.25, s=0.3, r=0.2), 1.95, 0.22)
S['intro'] = (echo(b, HR, 0.14, 0.3, 3), 0.9)

# --- write ------------------------------------------------------------------
tot = 0
for name, (sig, gain) in S.items():
    y = finish(sig) * gain
    save(f'{OUT}/{name}.wav', y)
    tot += os.path.getsize(f'{OUT}/{name}.wav')
    print(f'{name:12s} {len(y)/SR:5.2f}s  peak={np.max(np.abs(y)):.2f}')
print('total KB', tot // 1024, 'files', len(S))
