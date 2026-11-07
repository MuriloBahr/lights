import json
import random
from pathlib import Path

# size, count, par min, par max
TIERS = [(3, 8, 2, 5), (4, 14, 3, 8), (5, 16, 5, 12), (6, 12, 7, 16)]
OUT = Path(__file__).resolve().parent.parent / "data" / "levels.json"
NEIGHBORS = ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1))


def effects(n):
    masks = []
    for i in range(n * n):
        x, y = i % n, i // n
        mask = 0
        for dx, dy in NEIGHBORS:
            nx, ny = x + dx, y + dy
            if 0 <= nx < n and 0 <= ny < n:
                mask |= 1 << (ny * n + nx)
        masks.append(mask)
    return masks


def min_taps(n, state, eff):
    m = n * n
    rows = [eff[i] | (((state >> i) & 1) << m) for i in range(m)]
    pivots = []
    r = 0
    for c in range(m):
        p = next((i for i in range(r, m) if rows[i] >> c & 1), None)
        if p is None:
            continue
        rows[r], rows[p] = rows[p], rows[r]
        for i in range(m):
            if i != r and rows[i] >> c & 1:
                rows[i] ^= rows[r]
        pivots.append(c)
        r += 1

    base = 0
    for k, pc in enumerate(pivots):
        if rows[k] >> m & 1:
            base |= 1 << pc

    null = []
    for f in (c for c in range(m) if c not in pivots):
        vec = 1 << f
        for k, pc in enumerate(pivots):
            if rows[k] >> f & 1:
                vec |= 1 << pc
        null.append(vec)

    best = bin(base).count("1")
    for combo in range(1, 1 << len(null)):
        v = base
        for j, vec in enumerate(null):
            if combo >> j & 1:
                v ^= vec
        best = min(best, bin(v).count("1"))
    return best


def make_tier(n, count, lo, hi, rng):
    eff = effects(n)
    seen = set()
    found = []
    while len(found) < count:
        taps = rng.sample(range(n * n), rng.randint(lo, hi))
        state = 0
        for t in taps:
            state ^= eff[t]
        if state == 0 or state in seen:
            continue
        par = min_taps(n, state, eff)
        if not lo <= par <= hi:
            continue
        seen.add(state)
        found.append((par, state))
    found.sort()
    return found


def main():
    rng = random.Random(7)
    levels = []
    for n, count, lo, hi in TIERS:
        for par, state in make_tier(n, count, lo, hi, rng):
            grid = [(state >> i) & 1 for i in range(n * n)]
            levels.append({"id": len(levels) + 1, "size": n, "grid": grid, "par": par})

    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(lv, separators=(",", ":")) for lv in levels]
    OUT.write_text('{"levels":[\n' + ",\n".join(lines) + "\n]}\n", encoding="utf-8")
    print(f"{len(levels)} fases em {OUT}")


if __name__ == "__main__":
    main()