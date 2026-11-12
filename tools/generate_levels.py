import json
import random
from copy import deepcopy
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "data" / "levels.json"

SHAPES = {
    "self": ((0, 0),),
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
    "letra_k": ["#..#", "#.#.", "##..", "#.#."],
    "letra_a": [".##.", "#..#", "####", "#..#"],
    "letra_u": ["#..#", "#..#", "#..#", ".##."],
    "calendario": ["####", "#.#.", "####", "#..#"],
    "carinha": [".#.#.", ".#.#.", ".....", "#...#", ".###."],
    "coracao": [".#.#.", "#####", "#####", ".###.", "..#.."],
    "casa": ["..#..", ".###.", "#####", "#.#.#", "#.#.#"],
    "coroa": ["#..#", ".##.", "####", "#..#"],
    "rosto": ["#..#", "....", "#..#", ".##."],
    "coracao4": [".##.", "####", ".##.", "..#."],
    "nave": [".#..", "####", ".##.", "#..#"],
}

WORLDS = [
    {"id": 1, "name": "Clássico", "color": 0, "rule": "Tocar inverte a lâmpada e as vizinhas em cruz",
     "hint": "Toque numa luz: ela e as vizinhas invertem. Apague todas.", "boss": "Sonequinha"},
    {"id": 2, "name": "Diagonais", "color": 1, "rule": "Agora o toque inverte as diagonais",
     "hint": "Novidade: agora o toque inverte as diagonais.", "boss": "Coruja Estelar"},
    {"id": 3, "name": "Formas", "color": 2, "rule": "Nem toda grade é quadrada",
     "hint": "Novidade: só existem lâmpadas onde elas aparecem.", "boss": "Nuvem Guardiã"},
    {"id": 4, "name": "Mistura", "color": 3, "rule": "Cruz, diagonais e formas juntas",
     "hint": "Tudo junto: observe a regra de cada fase.", "boss": "Camaleão"},
    {"id": 5, "name": "Espelho", "color": 4, "rule": "Cada toque ecoa no espelho do tabuleiro",
     "hint": "O toque reverbera no centro: o espelho repete o efeito.", "boss": "Gêmeos Lunares"},
    {"id": 6, "name": "Raio", "color": 5, "rule": "A energia percorre a linha e a coluna do toque",
     "hint": "A energia dispara em linha reta: a fileira e a coluna também mudam.", "boss": "Polvo Elétrico"},
    {"id": 7, "name": "Pintura", "color": 0, "rule": "Acenda as luzes para formar o desenho",
     "hint": "Novo objetivo: deixe as luzes iguais à miniatura.", "boss": "Monstrinho Pintor"},
    {"id": 8, "name": "Ondas", "color": 2, "rule": "Um toque muda a fileira inteira",
     "hint": "Toque em qualquer luz da fileira que deseja inverter.", "boss": "Baleia Aurora"},
    {"id": 9, "name": "Chuva de Estrelas", "color": 5, "rule": "Um toque muda a coluna inteira",
     "hint": "Toque em qualquer luz da coluna que deseja inverter.", "boss": "Guardião Meteoro"},
    {"id": 10, "name": "Luz Final", "color": 3, "rule": "Copie o desenho iluminando as luzes certas",
     "hint": "Compare o tabuleiro com o desenho de referência.", "boss": "Rainha da Escuridão"},
]

# Keep the established campaign order (Painting follows Classic) so “Next”
# still follows the same world path. Existing phases are retained in-place;
# the generator fills each world to 20 and puts its boss on phase 20.
WORLD_ORDER = (1, 7, 2, 3, 4, 5, 6, 8, 9, 10)
LEVELS_PER_WORLD = 20

ROW_COLUMN_MASKS = ("diamante5", "coracao5", "ampulheta5", "anel5")
PAINTING_GOALS_3 = ("mais", "cantos", "moldura", "xis3")
PAINTING_GOALS_4 = ("quadrado", "diagonal", "xis4", "letra_k", "calendario", "coroa", "rosto", "coracao4", "nave")
PAINTING_EASTER_EGGS = {
    17: ("K", "letra_k"),
    18: ("A", "letra_a"),
    19: ("U", "letra_u"),
    20: ("04 · 10", "calendario"),
}


def level_plan(world, phase):
    """Return a gentle, varied puzzle recipe for a new phase."""
    low = 1 if phase <= 20 else 2
    high = 1 if phase <= 8 else (2 if phase <= 20 else 3)
    if phase == LEVELS_PER_WORLD:
        low, high = 2, 3

    if world == 1:
        return "plus", 3 if phase <= 20 else 4, low, high, "none", None
    if world == 2:
        return "x", 3 if phase <= 20 else 4, low, high, "none", None
    if world == 3:
        return "plus", ("cruz3" if phase % 2 else "anel3"), low, high, "none", None
    if world == 4:
        shape = "plus" if phase % 2 else "x"
        key = "cruz3" if phase % 4 == 1 else ("anel3" if phase % 4 == 3 else (3 if phase <= 20 else 4))
        return shape, key, low, high, "none", None
    if world == 5:
        shape = "plus" if phase % 2 else "x"
        return shape, 3 if phase <= 20 else 4, low, high, "mirror", None
    if world == 6:
        shape = "plus" if phase % 2 else "x"
        return shape, 3 if phase <= 20 else 4, low, high, "line", None
    if world == 7:
        if phase in PAINTING_EASTER_EGGS:
            egg, goal = PAINTING_EASTER_EGGS[phase]
            return "plus", 4, 1, 1, "none", goal
        if phase <= 14:
            return "plus", 3, low, high, "none", PAINTING_GOALS_3[(phase - 1) % len(PAINTING_GOALS_3)]
        return "plus", 4, low, high, "none", PAINTING_GOALS_4[(phase - 15) % len(PAINTING_GOALS_4)]
    if world == 8:
        keys = (4, *ROW_COLUMN_MASKS)
        return "self", keys[(phase - 1) % len(keys)], low, high, "row", None
    if world == 9:
        keys = (4, *ROW_COLUMN_MASKS)
        return "self", keys[(phase - 1) % len(keys)], low, high, "column", None
    if world == 10:
        if phase % 4 == 0:
            return "plus", 5, low, high, "none", ("carinha", "coracao", "casa")[(phase // 4) % 3]
        return "plus", 4, low, high, "none", PAINTING_GOALS_4[(phase - 1) % len(PAINTING_GOALS_4)]
    raise ValueError(f"mundo inválido: {world}")


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
        elif effect == "row":
            for ix in range(n):
                targets.add(y * n + ix)
        elif effect == "column":
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
            if state == 0 or (shape, tuple(cells), effect, goal, state) in seen:
                continue
            sol = solve(cells, eff, state)
            if sol is None or not lo - relax <= len(sol) <= hi + relax:
                continue
            check = 0
            for t in sol:
                check ^= eff[t]
            assert check == state
            seen.add((shape, tuple(cells), effect, goal, state))
            return n, cells, state ^ goal, sol, effect, goal
    raise RuntimeError(f"sem fase para {shape} {key} {lo}-{hi} {effect} {goal_name}")


def main():
    rng = random.Random(21)
    levels = []
    seen_by_world = {world["id"]: set() for world in WORLDS}
    old_by_world = {world["id"]: [] for world in WORLDS}
    if OUT.exists():
        old_data = json.loads(OUT.read_text(encoding="utf-8"))
        for level in old_data.get("levels", []):
            old_by_world.setdefault(int(level["world"]), []).append(level)

    # Keep previous boards and romantic easter eggs, but move their phase IDs
    # into the 20-phase world blocks.
    for world in WORLD_ORDER:
        for old_level in old_by_world.get(world, []):
            n = int(old_level["size"])
            cells = tuple(i for i, active in enumerate(old_level.get("mask", [1] * (n * n))) if active)
            goal = sum(int(value) << i for i, value in enumerate(old_level.get("goal", [0] * (n * n))))
            start = sum(int(value) << i for i, value in enumerate(old_level["grid"]))
            seen_by_world[world].add((old_level.get("shape", "plus"), cells, old_level.get("effect", "none"), goal, start ^ goal))

    for world in WORLD_ORDER:
        old_levels = old_by_world.get(world, [])
        for phase in range(1, LEVELS_PER_WORLD + 1):
            is_painting_egg = world == 7 and phase in PAINTING_EASTER_EGGS
            if phase <= len(old_levels) and not is_painting_egg:
                level = deepcopy(old_levels[phase - 1])
            else:
                shape, key, lo, hi, effect, goal_name = level_plan(world, phase)
                n, cells, state, solution, effect, goal = make_level(shape, key, lo, hi, rng, seen_by_world[world], effect, goal_name)
                level = {"world": world, "size": n,
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

            if is_painting_egg:
                egg, _goal_name = PAINTING_EASTER_EGGS[phase]
                level["easter_egg"] = egg
                if egg == "04 · 10":
                    level["title"] = egg
                else:
                    level.pop("title", None)

            level["id"] = len(levels) + 1
            level["world"] = world
            level.pop("boss", None)
            if phase == 1:
                level.setdefault("hint", WORLDS[world - 1]["hint"])
            elif is_painting_egg:
                level["hint"] = "Forme a letra %s." % PAINTING_EASTER_EGGS[phase][0] if phase < 20 else "Forme a data especial."
            elif "goal" in level:
                level.setdefault("hint", "Forme o desenho da miniatura.")
            else:
                level.setdefault("hint", WORLDS[world - 1]["hint"])
            if phase == LEVELS_PER_WORLD:
                level["boss"] = WORLDS[world - 1]["boss"]
            levels.append(level)

    worlds = [{k: v for k, v in w.items() if k != "hint"} for w in WORLDS]
    OUT.parent.mkdir(parents=True, exist_ok=True)
    lines = [json.dumps(lv, ensure_ascii=False, separators=(",", ":")) for lv in levels]
    head = json.dumps({"worlds": worlds}, ensure_ascii=False, separators=(",", ":"))[:-1]
    OUT.write_text(head + ',"levels":[\n' + ",\n".join(lines) + "\n]}\n", encoding="utf-8")
    print(f"{len(levels)} fases ({LEVELS_PER_WORLD} por mundo) em {OUT}")


if __name__ == "__main__":
    main()
