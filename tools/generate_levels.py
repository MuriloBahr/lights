import json
import random
from pathlib import Path
from itertools import groupby

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

GOALS = {
    "mais": [".#.", "###", ".#."],
    "cantos": ["#.#", "...", "#.#"],
    "moldura": ["###", "#.#", "###"],
    "xis3": ["#.#", ".#.", "#.#"],
    "quadrado": ["####", "#..#", "#..#", "####"],
    "diagonal": ["#...", ".#..", "..#.", "...#"],
    "xis4": ["#..#", ".##.", ".##.", "#..#"],
    "carinha": [".#.#.", ".#.#.", ".....", "#...#", ".###."],
    "coracao": [".#.#.", "#####", "#####", ".###.", "..#.."],
    "casa": ["..#..", ".###.", "#####", "#.#.#", "#.#.#"],
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
    {"id": 5, "name": "Espelho", "color": 4, "rule": "Cada toque ecoa no espelho do tabuleiro",
     "hint": "O toque reverbera no centro: o espelho repete o efeito."},
    {"id": 6, "name": "Raio", "color": 5, "rule": "A energia percorre a linha e a coluna do toque",
     "hint": "A energia dispara em linha reta: a fileira e a coluna também mudam."},
    {"id": 7, "name": "Pintura", "color": 0, "rule": "Acenda as luzes para formar o desenho",
     "hint": "Novo objetivo: deixe as luzes iguais à miniatura."},
]

# (world, shape, size or mask name, par min, par max, effect, goal)
# Keep every board small and every solution short. New rules vary the feel,
# while the player never needs to plan a long sequence just to pass a level.
PLAN = (
    [(1, "plus", 3, 1, 1)] * 6
    + [(1, "plus", 3, 1, 2)] * 4
    + [(1, "plus", 3, 2, 3)] * 2
    + [(7, "plus", 3, 1, 2, "none", "todas")] * 2
    + [(7, "plus", 3, 1, 2, "none", g) for g in ("mais", "cantos", "moldura", "xis3")] * 2
    + [(7, "plus", 3, 1, 2, "none", "mais")] * 2
    + [(7, "plus", 4, 1, 2, "none", g) for g in ("quadrado", "diagonal", "xis4")] * 4
    + [(2, "x", 3, 1, 2)] * 6
    + [(2, "x", 4, 2, 3)] * 6
    + [(3, "plus", "cruz3", 1, 2)] * 3
    + [(3, "plus", "anel3", 1, 2)] * 3
    + [(3, "plus", "cruz3", 2, 3)] * 3
    + [(3, "plus", "anel3", 2, 3)] * 3
    + [(4, "plus", 3, 1, 2)] * 3
    + [(4, "x", 3, 1, 2)] * 3
    + [(4, "plus", "cruz3", 1, 2)] * 3
    + [(4, "x", "anel3", 1, 2)] * 3
    + [(5, "plus", 3, 1, 2, "mirror")] * 3
    + [(5, "x", 3, 1, 2, "mirror")] * 3
    + [(5, "plus", 3, 2, 3, "mirror")] * 3
    + [(6, "plus", 3, 1, 2, "line")] * 3
    + [(6, "x", 3, 1, 2, "line")] * 3
    + [(6, "plus", 3, 2, 3, "line")] * 3
)


def geometry(key):
    if isinstance(key, int):
        return key, list(range(key * key))
    rows = MASKS[key]
    n = len(rows)
    return n, [y * n + x for y in range(n) for x in range(n) if rows[y][x] == "#"]


def effects(n, cells, offsets, effect="none"):
    active = set(cells)
    eff = {}
    for j in cells:
        x, y = j % n, j // n
        targets = set()
        for dx, dy in offsets:
            nx, ny = x + dx, y + dy
            if 0 <= nx < n and 0 <= ny < n:
                idx = ny * n + nx
                if idx in active:
                    targets.add(idx)
        if effect == "mirror":
            targets.add((n - 1 - x) + (n - 1 - y) * n)
        elif effect == "line":
            for ix in range(n):
                targets.add(y * n + ix)
            for iy in range(n):
                targets.add(iy * n + x)
        mask = 0
        for idx in targets:
            if idx in active:
                mask |= 1 << idx
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


def goal_state(n, cells, name):
    if name is None:
        return 0
    if name == "todas":
        return sum(1 << c for c in cells)
    rows = GOALS[name]
    state = sum(1 << (y * n + x) for y in range(n) for x in range(n) if rows[y][x] == "#")
    assert all(i in cells for i in range(n * n) if state >> i & 1)
    return state


def make_level(shape, key, lo, hi, rng, seen, effect="none", goal_name=None):
    n, cells = geometry(key)
    goal = goal_state(n, cells, goal_name)
    eff = effects(n, cells, SHAPES[shape], effect)
    for relax in range(8):
        for _ in range(3000):
            k = rng.randint(max(1, lo - relax), min(len(cells), hi + relax))
            state = 0
            for t in rng.sample(cells, k):
                state ^= eff[t]
            if state == 0 or (shape, key, effect, goal, state) in seen:
                continue
            sol = solve(cells, eff, state)
            if sol is None or not lo - relax <= len(sol) <= hi + relax:
                continue
            check = 0
            for t in sol:
                check ^= eff[t]
            assert check == state
            seen.add((shape, key, effect, goal, state))
            return n, cells, state ^ goal, sol, effect, goal
    raise RuntimeError(f"sem fase para {shape} {key} {lo}-{hi} {effect} {goal_name}")


def main():
    rng = random.Random(21)
    seen = set()
    levels = []
    first = set()
    for entry, run in groupby(PLAN):
        world, shape, key, lo, hi = entry[:5]
        effect = entry[5] if len(entry) > 5 else "none"
        goal_name = entry[6] if len(entry) > 6 else None
        built = [make_level(shape, key, lo, hi, rng, seen, effect, goal_name) for _ in run]
        built.sort(key=lambda b: len(b[3]))
        for n, cells, state, solution, effect, goal in built:
            level = {"id": len(levels) + 1, "world": world, "size": n,
                     "grid": [(state >> i) & 1 for i in range(n * n)], "par": len(solution),
                     "solution": solution}
            if effect != "none":
                level["effect"] = effect
            if shape != "plus":
                level["shape"] = shape
            if len(cells) != n * n:
                level["mask"] = [1 if i in cells else 0 for i in range(n * n)]
            if goal:
                level["goal"] = [(goal >> i) & 1 for i in range(n * n)]
            if level["id"] == 1:
                level["hint"] = "Vamos juntos: toque na lâmpada acesa para ver as vizinhas mudarem."
            elif level["id"] <= 3:
                level["hint"] = "Toque na lâmpada e observe a cruz. Não há limite de tentativas!"
            elif level["id"] <= 6:
                level["hint"] = "Apague todas as luzes. Use Desfazer ou Dica quando quiser."
            if world not in first:
                first.add(world)
                level.setdefault("hint", WORLDS[world - 1]["hint"])
            elif goal:
                level["hint"] = "Forme o desenho da miniatura."
            levels.append(level)

    worlds = [{k: v for k, v in w.items() if k != "hint"} for w in WORLDS]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(lv, ensure_ascii=False, separators=(",", ":")) for lv in levels]
    head = json.dumps({"worlds": worlds}, ensure_ascii=False, separators=(",", ":"))[:-1]
    OUT.write_text(head + ',"levels":[\n' + ",\n".join(lines) + "\n]}\n", encoding="utf-8")
    print(f"{len(levels)} fases em {OUT}")


if __name__ == "__main__":
    main()
