import numpy as np
from scipy.signal import resample_poly, butter, lfilter
from scipy.io import wavfile

OS = 4            # oversampling factor for synthesis
SR = 44100
HR = SR * OS      # synthesis rate

def t_arr(dur):
    return np.arange(int(dur * HR)) / HR

def midi(n):
    names = {'C':0,'D':2,'E':4,'F':5,'G':7,'A':9,'B':11}
    name, rest = n[0], n[1:]
    acc = 0
    if rest.startswith('#'): acc, rest = 1, rest[1:]
    elif rest.startswith('b'): acc, rest = -1, rest[1:]
    return 12 * (int(rest) + 1) + names[name] + acc

def hz(n):
    return 440.0 * 2 ** ((midi(n) - 69) / 12) if isinstance(n, str) else float(n)

def env(n, a=0.004, d=0.05, s=0.6, r=0.04, sr=HR):
    """ADSR on n samples; release occupies the tail."""
    A, D, R = int(a*sr), int(d*sr), int(r*sr)
    e = np.ones(n) * s
    A = min(A, n); e[:A] = np.linspace(0, 1, A, endpoint=False) if A else 1
    D2 = min(D, max(n - A, 0))
    if D2: e[A:A+D2] = np.linspace(1, s, D2, endpoint=False)
    R = min(R, n)
    if R: e[n-R:] *= np.linspace(1, 0, R)
    return e

def phase(freq):
    freq = np.asarray(freq, dtype=float)
    return np.cumsum(freq) / HR

def pulse_p(ph, duty=0.5):
    return np.where((ph % 1.0) < duty, 1.0, -1.0)

def tri_p(ph):
    return 2 * np.abs(2 * ((ph % 1.0)) - 1) - 1

def sine_p(ph):
    return np.sin(2 * np.pi * ph)

def noise(n, seed=1):
    return np.random.default_rng(seed).uniform(-1, 1, n)

def lp(x, cutoff, order=2, sr=HR):
    b, a = butter(order, cutoff / (sr / 2), btype='low'); return lfilter(b, a, x)

def hp(x, cutoff, order=2, sr=HR):
    b, a = butter(order, cutoff / (sr / 2), btype='high'); return lfilter(b, a, x)

def bp(x, lo, hi, order=2, sr=HR):
    b, a = butter(order, [lo/(sr/2), hi/(sr/2)], btype='band'); return lfilter(b, a, x)

def blip(f0, dur, wave='pulse', duty=0.5, f1=None, vol=1.0, a=0.003, d=0.04, s=0.5, r=0.02, vib=0.0, vibhz=6):
    t = t_arr(dur)
    f = np.linspace(f0, f1 if f1 else f0, len(t))
    if vib: f = f * (1 + vib * np.sin(2*np.pi*vibhz*t))
    ph = phase(f)
    w = {'pulse': lambda: pulse_p(ph, duty), 'tri': lambda: tri_p(ph), 'sine': lambda: sine_p(ph)}[wave]()
    return w * env(len(t), a, d, s, r) * vol

def place(buf, sig, at, vol=1.0):
    i = int(at * HR)
    end = min(len(buf), i + len(sig))
    if end > i: buf[i:end] += sig[:end-i] * vol
    return buf

def downsample(x, factor=OS):
    return resample_poly(x, 1, factor)

def finish(x, peak=0.85, fade_ms=6):
    x = downsample(x)
    m = np.max(np.abs(x)) or 1.0
    x = x / m * peak
    n = int(SR * fade_ms / 1000)
    if n and len(x) > 2*n:
        x[:n] *= np.linspace(0, 1, n); x[-n:] *= np.linspace(1, 0, n)
    return x

def save(path, x, sr=SR):
    wavfile.write(path, sr, (np.clip(x, -1, 1) * 32767).astype(np.int16))

def echo(x, sr, delay, fb=0.3, taps=4, wet=1.0):
    out = x.copy()
    d = int(delay * sr)
    for k in range(1, taps + 1):
        sh = d * k
        if sh < len(x): out[sh:] += x[:len(x)-sh] * (fb ** k) * wet
    return out
