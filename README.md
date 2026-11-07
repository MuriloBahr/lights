# Lights

Jogo de lógica para Android e iOS feito em Godot 4. Uma grade de luzes, e tocar em uma célula inverte ela e as quatro vizinhas. O objetivo é apagar tudo no menor número de toques.

## Stack

- Godot 4.x (GDScript)
- Python 3 (gerador de fases)
- JSON para fases e progresso salvo

## Estrutura

```
data/
  levels.json          fases geradas, fonte única de verdade
scripts/
  board.gd             lógica do tabuleiro, sem dependência de interface
  game.gd              tela de jogo, monta a grade por código
scenes/
  game.tscn
tools/
  generate_levels.py   gera o levels.json
assets/
```

## Como rodar

1. Gere as fases (só precisa repetir se mudar o gerador):

   ```
   python tools/generate_levels.py
   ```

2. Abra a pasta do projeto no Godot e aperte F5.

## Formato das fases

```json
{ "id": 1, "size": 3, "grid": [0,1,0,1,1,1,0,1,0], "par": 1 }
```

- `size`: lado da grade
- `grid`: células em ordem de linha, `1` para acesa
- `par`: mínimo exato de toques, calculado por eliminação gaussiana em GF(2)

O gerador parte da grade apagada e aplica toques aleatórios, então toda fase tem solução. As fases saem ordenadas por dificuldade: 8 em 3x3, 14 em 4x4, 16 em 5x5 e 12 em 6x6.

## Board

`board.gd` não conhece a interface. A tela escuta os sinais e só desenha o estado.

- `load_level(dict)`, `toggle(x, y)`, `undo()`, `reset()`, `is_solved()`
- Sinais: `changed`, `solved`

## Roadmap

- [x] Tabuleiro jogável
- [ ] Menu e seleção de fases
- [ ] Progresso e estrelas salvos em `user://save.json`
- [ ] Visual, som e ícone
- [ ] Build Android (AAB) e teste fechado na Play Store
- [ ] Build iOS
