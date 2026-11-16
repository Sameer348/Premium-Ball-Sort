"""Synthesizes Sort Sphere's original sound effects and ambient loop.

Built only from sine / filtered-noise primitives: no third-party audio.
Run:  python3 tool/generate_audio.py
"""
import math, random, struct, wave, os

SR = 22050
OUT = os.path.join(os.path.dirname(__file__), '..', 'assets')


def write(path, s):
    peak = max(1e-6, max(abs(v) for v in s))
    k = min(1.0, 0.85 / peak)
    with wave.open(os.path.join(OUT, path), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, v * k)) * 32767)) for v in s))


def tone(dur, f0, f1=None, a=0.004, d=0.08, harm=(1.0, 0.25, 0.08)):
    f1 = f0 if f1 is None else f1
    out, ph = [], 0.0
    n = int(dur * SR)
    for i in range(n):
        t = i / SR
        f = f0 * (f1 / f0) ** (t / dur)
        ph += 2 * math.pi * f / SR
        e = t / a if t < a else math.exp(-(t - a) / d)
        out.append(sum(h * math.sin(ph * (j + 1)) for j, h in enumerate(harm)) * e)
    return out


def noise(dur, d=0.05, lp=0.15, seed=1):
    r = random.Random(seed); y = 0.0; out = []
    for i in range(int(dur * SR)):
        y += lp * (r.uniform(-1, 1) - y)
        out.append(y * math.exp(-(i / SR) / d))
    return out


def mix(*parts):
    """parts: (samples, offset_sec, gain)"""
    n = max(int(o * SR) + len(s) for s, o, g in parts)
    out = [0.0] * n
    for s, o, g in parts:
        st = int(o * SR)
        for i, v in enumerate(s):
            out[st + i] += v * g
    return out


def chime(notes, step, d=0.35):
    return mix(*[(tone(d * 2.5, f, d=d, harm=(1, 0.4, 0.15, 0.05)), i * step, 1) for i, f in enumerate(notes)])


write('sounds/select.wav', tone(0.09, 880, 1040, d=0.03, harm=(1, 0.2)))
write('sounds/pickup.wav', tone(0.12, 520, 780, d=0.05))
write('sounds/move.wav', mix((noise(0.22, d=0.08, lp=0.06, seed=3), 0, 0.8), (tone(0.2, 300, 600, d=0.07, harm=(1,)), 0, 0.3)))
write('sounds/drop.wav', mix((tone(0.18, 640, 420, d=0.045, harm=(1, 0.5, 0.2)), 0, 1), (noise(0.05, d=0.01, lp=0.5, seed=7), 0, 0.25)))
write('sounds/invalid.wav', mix((tone(0.16, 220, 180, d=0.06, harm=(1, 0.3)), 0, 1), (tone(0.16, 233, 190, d=0.06, harm=(1,)), 0.02, 0.6)))
write('sounds/tube_complete.wav', chime([784, 988, 1175, 1568], 0.06, d=0.25))
write('sounds/level_complete.wav', chime([523, 659, 784, 1047, 1319, 1568], 0.11, d=0.45))
write('sounds/coin.wav', mix((tone(0.25, 1319, d=0.08, harm=(1, 0.5)), 0, 1), (tone(0.3, 1760, d=0.1, harm=(1, 0.3)), 0.06, 0.8)))
write('sounds/star.wav', chime([1047, 1568], 0.05, d=0.2))
write('sounds/button.wav', tone(0.07, 660, 720, d=0.025, harm=(1, 0.15)))
write('sounds/booster.wav', mix((tone(0.4, 400, 1200, d=0.15, harm=(1, 0.3, 0.1)), 0, 0.8), (noise(0.3, d=0.1, lp=0.05, seed=9), 0, 0.4)))
write('sounds/achievement.wav', chime([659, 831, 988, 1319, 1661], 0.09, d=0.5))

# Ambient loop: slow evolving pad (Cmaj7 → Am9 → Fmaj7 → G6), 24 s.
chords = [[130.8, 196.0, 246.9, 329.6], [110.0, 164.8, 246.9, 261.6], [87.3, 174.6, 220.0, 329.6], [98.0, 146.8, 246.9, 293.7]]
dur = 24.0
n = int(dur * SR)
seg = n // len(chords)
pad = [0.0] * n
for ci, ch in enumerate(chords):
    for i in range(seg + SR):  # 1 s overlap crossfade
        idx = (ci * seg + i) % n
        t = i / SR
        env = min(1.0, t / 1.5) * min(1.0, max(0.0, (seg / SR + 1 - t) / 1.5))
        v = 0.0
        for k, f in enumerate(ch):
            v += math.sin(2 * math.pi * f * (idx / SR) + k) * (0.5 + 0.5 * math.sin(2 * math.pi * 0.07 * (idx / SR) + k))
            v += 0.3 * math.sin(2 * math.pi * f * 2.003 * (idx / SR))
        pad[idx] += v * env * 0.12
# sparse bell sparkles
r = random.Random(42)
for _ in range(14):
    st = r.uniform(0, dur - 2)
    f = r.choice([1047, 1175, 1319, 1568, 1760])
    b = tone(1.8, f, d=0.6, harm=(1, 0.2))
    s0 = int(st * SR)
    for i, v in enumerate(b):
        pad[(s0 + i) % n] += v * 0.05
write('music/ambient_loop.wav', pad)
print('audio written')
