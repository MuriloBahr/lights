import json
import random
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "data" / "levels.json"

SHAPES = {
    "plus": ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)),
    "x": ((0, 0), (1, 1), (-1, 1), (1, -1), (-1, -1)),
}

MASKS = {
    "cruz3": [".#.", "###", ".#."],
    "anel3": ["###", "#.#", "###"],
    "diamante5": ["..#..", ".###.", "#####", ".###.", "..#.."],
    "coracao5": [".#.#.", "#####", "#####", ".###.", "..#.."],
    "ampulheta5": ["#####", ".###.", "..#..", ".###.", "#####"],
    "casa5": ["..#..", ".###.", "#####", "#####", "#####"],
    "anel5": ["#####", "#...#", "#...#", "#...#", "#####"],
}

WORLDS = [
    {"id": 1, "name": "Clássico", "color": 0, "rule": "Tocar inverte a lâmpada e as vizinhas em cruz",
     "hint": "Toque numa luz: ela e as vizinhas invertem. Apague todas."},
    {"id": 2, "name": "Diagonais", "color": 1, "rule": "Agora o toque inverte as diagonais",
     "hint": "Novidade: agora o toque inverte as diagonais."},
    {"id": 3, "name": "Formas", "color": 2, "rule": "Nem toda grade é quadrada",
     "hint": "Novidade: só existem lâmpadas onde elas aparecem."},
    {"id": 4, "name": "Mistura", "color": 3, "rule": "Cruz, diagonais e formas juntas",
     "hint": "Tudo junto: observe a regra de cada fase."},
]

# (world, shape, size or mask name, par min, par max)
PLAN = (
    [(1, "plus", 3, 1, 1)] * 3 + [(1, "plus", 3, 2, 3)] * 3 + [(1, "plus", 4, 3, 5)] * 3 + [(1, "plus", 5, 4, 7)] * 3
    + [(2, "x", 3, 1, 2)] * 3 + [(2, "x", 4, 2, 4)] * 3 + [(2, "x", 5, 3, 6)] * 3 + [(2, "x", 5, 5, 9)] * 3
    + [
        (3, "plus", "cruz3", 1, 3), (3, "plus", "anel3", 2, 4), (3, "plus", "cruz3", 2, 3),
        (3, "plus", "anel3", 3, 5), (3, "plus", "diamante5", 3, 6), (3, "plus", "coracao5", 3, 6),
        (3, "plus", "ampulheta5", 3, 6), (3, "plus", "casa5", 4, 7), (3, "plus", "anel5", 4, 8),
        (3, "plus", "diamante5", 5, 9), (3, "plus", "coracao5", 5, 9), (3, "plus", "ampulheta5", 5, 9),
    ]
    + [
        (4, "plus", 5, 6, 10), (4, "x", 5, 5, 9), (4, "plus", "coracao5", 5, 9), (4, "x", "diamante5", 4, 8),
        (4, "plus", 6, 7, 12), (4, "x", 6, 6, 12), (4, "plus", "ampulheta5", 5, 9), (4, "x", "casa5", 4, 8),
        (4, "plus", 6, 9, 14), (4, "x", 6, 8, 14), (4, "plus", 6, 11, 16), (4, "plus", 6, 12, 18),
    ]
)


def geometry(key):
    if isinstance(key, int):
        return key, list(range(key * key))
    rows = MASKS[key]
    n = len(rows)
    return n, [y * n + x for y in range(n) for x in range(n) if rows[y][x] == "#"]


def effects(n, cells, offsets):
    active = set(cells)
    eff = {}
    for j in cells:
        x, y = j % n, j // n
        mask = 0
        for dx, dy in offsets:
            nx, ny = x + dx, y + dy
            if 0 <= nx < n and 0 <= ny < n and ny * n + nx in active:
                mask |= 1 << (ny * n + nx)
        eff[j] = mask
    return eff


def solve(cells, eff, state):
    m = len(cells)
    rows = []
    for i in cells:
        row = 0
        for k, j in enumerate(cells):
            if eff[j] >> i & 1:
                row |= 1 << k
        rows.append(row | (((state >> i) & 1) << m))

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
    if any(rows[i] >> m & 1 for i in range(r, m)):
        return None

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
    if len(null) > 14:
        return None

    best = base
    for combo in range(1, 1 << len(null)):
        v = base
        for j, vec in enumerate(null):
            if combo >> j & 1:
                v ^= vec
        if bin(v).count("1") < bin(best).count("1"):
            best = v
    return [cells[k] for k in range(m) if best >> k & 1]


def make_level(shape, key, lo, hi, rng, seen):
    n, cells = geometry(key)
    eff = effects(n, cells, SHAPES[shape])
    for relax in range(8):
        for _ in range(3000):
            k = rng.randint(max(1, lo - relax), min(len(cells), hi + relax))
            state = 0
            for t in rng.sample(cells, k):
                state ^= eff[t]
            if state == 0 or (shape, key, state) in seen:
                continue
            sol = solve(cells, eff, state)
            if sol is None or not lo - relax <= len(sol) <= hi + relax:
                continue
            check = 0
            for t in sol:
                check ^= eff[t]
            assert check == state
            seen.add((shape, key, state))
            return n, cells, state, len(sol)
    raise RuntimeError(f"sem fase para {shape} {key} {lo}-{hi}")


def main():
    rng = random.Random(21)
    seen = set()
    levels = []
    first = set()
    for world, shape, key, lo, hi in PLAN:
        n, cells, state, par = make_level(shape, key, lo, hi, rng, seen)
        level = {"id": len(levels) + 1, "world": world, "size": n,
                 "grid": [(state >> i) & 1 for i in range(n * n)], "par": par}
        if shape != "plus":
            level["shape"] = shape
        if len(cells) != n * n:
            level["mask"] = [1 if i in cells else 0 for i in range(n * n)]
        if world not in first:
            first.add(world)
            level["hint"] = WORLDS[world - 1]["hint"]
        levels.append(level)

    worlds = [{k: v for k, v in w.items() if k != "hint"} for w in WORLDS]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(lv, ensure_ascii=False, separators=(",", ":")) for lv in levels]
    head = json.dumps({"worlds": worlds}, ensure_ascii=False, separators=(",", ":"))[:-1]
    OUT.write_text(head + ',"levels":[\n' + ",\n".join(lines) + "\n]}\n", encoding="utf-8")
    print(f"{len(levels)} fases em {OUT}")


if __name__ == "__main__":
    main()