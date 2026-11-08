import math
import random
import struct
import wave
from pathlib import Path

RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "sfx"


def write(name, samples):
    peak = max(abs(s) for s in samples) or 1.0
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b"".join(struct.pack("<h", int(s / peak * 0.8 * 32767)) for s in samples))


def tap():
    out = []
    phase = 0.0
    for i in range(int(RATE * 0.15)):
        t = i / RATE
        phase += 2 * math.pi * (450 + 450 * math.exp(-t / 0.02)) / RATE
        out.append(math.sin(phase) * math.exp(-t / 0.045) * min(1.0, t / 0.002))
    return out


def click():
    out = []
    phase = 0.0
    for i in range(int(RATE * 0.09)):
        t = i / RATE
        phase += 2 * math.pi * (700 + 500 * math.exp(-t / 0.012)) / RATE
        out.append(math.sin(phase) * math.exp(-t / 0.028) * min(1.0, t / 0.001))
    return out


def start():
    rng = random.Random(3)
    dur = 0.45
    low = band = 0.0
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        fc = 300 * 2 ** (t / dur * 4)
        f = 2 * math.sin(math.pi * fc / RATE)
        high = rng.uniform(-1, 1) - low - 0.15 * band
        band += f * high
        low += f * band
        out.append(band * math.sin(math.pi * t / dur) ** 1.5)
    return out


def enter():
    rng = random.Random(5)
    sweep = 0.45
    n = int(RATE * 0.8)
    out = [0.0] * n
    low = band = 0.0
    for i in range(int(RATE * sweep)):
        t = i / RATE
        f = 2 * math.sin(math.pi * 500 * 6 ** (t / sweep) / RATE)
        high = rng.uniform(-1, 1) - low - 0.2 * band
        band += f * high
        low += f * band
        out[i] = band * (t / sweep) ** 1.5
    peak = max(abs(x) for x in out) or 1.0
    out = [x / peak * 0.45 for x in out]
    start = int(RATE * sweep)
    for i in range(int(RATE * 0.25)):
        t = i / RATE
        j = start + i
        if j >= n:
            break
        out[j] += math.sin(2 * math.pi * 110 * t) * math.exp(-t / 0.07) * min(1.0, t / 0.002)
        out[j] += rng.uniform(-1, 1) * math.exp(-t / 0.02) * 0.25
    return out


def win():
    notes = [(523.25, 0.0), (659.25, 0.11), (783.99, 0.22), (1046.5, 0.33)]
    n = int(RATE * 1.2)
    out = [0.0] * n
    for freq, start in notes:
        for i in range(int(RATE * 0.7)):
            idx = int(start * RATE) + i
            if idx >= n:
                break
            t = i / RATE
            env = math.exp(-t / 0.22) * min(1.0, t / 0.003)
            out[idx] += env * (math.sin(2 * math.pi * freq * t) + 0.3 * math.sin(4 * math.pi * freq * t))
    return out


if __name__ == "__main__":
    write("tap.wav", tap())
    write("win.wav", win())
    write("click.wav", click())
    write("start.wav", start())
    write("enter.wav", enter())
    print(f"sons em {OUT}")