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
- `effect`: opcional, adiciona regras especiais como `mirror` (eco no espelho) e `line` (raio em linha e coluna)
- `solution`: lista de toques que resolve a fase; a quantidade de dicas disponíveis acompanha o `par`

Novas regras especiais ajudam a manter o jogo mais dinâmico sem perder a sensação de lógica: o mundo `Espelho` repete o toque no centro do tabuleiro, e o mundo `Raio` dispara energia por fileira e coluna.

As lâmpadas mantêm cores variadas. Cada mundo tem seu próprio fundo ilustrado e cor de destaque, também usados na seleção de fases. Antes da primeira fase de cada mundo, uma demonstração interativa apresenta a regra nova. As primeiras seis fases do mundo Clássico são introduções de uma jogada. A partir daí, a dificuldade sobe aos poucos. Cada fase oferece uma dica por jogada mínima (`par`); dicas não usadas não são gastas e reiniciar restaura a quantidade.

O gerador parte da grade apagada e aplica toques aleatórios, então toda fase tem solução. O projeto contém 66 fases distribuídas por seis mundos, com dificuldade crescente.

## Layout para telas

As telas ajustam margens, tamanho das lâmpadas, botões e colunas de fases conforme o viewport. Em aparelhos estreitos, as ações do tabuleiro passam para duas linhas; painéis de ajuda podem rolar verticalmente. O projeto usa uma base vertical de 540 × 960 com expansão de aspecto para acomodar diferentes proporções.

## Extras

- Efeitos em cascata quando uma jogada altera as lâmpadas, mais brilho ao resolver.
- Som de acender/apagar com variação de tom, vibração configurável e feedback de combo por jogadas que apagam luzes.
- Fundos temáticos estáticos para reduzir redesenho contínuo; animações acontecem sob demanda ao interagir com as lâmpadas.
- Desafio diário sem cronômetro, escolhido por data local e com conclusão salva em `user://save.json`. Ele não altera o desbloqueio das fases normais.

## Board

`board.gd` não conhece a interface. A tela escuta os sinais e só desenha o estado.

- `load_level(dict)`, `toggle(x, y)`, `undo()`, `reset()`, `is_solved()`
- Sinais: `changed`, `solved`

## Roadmap

- [x] Tabuleiro jogável
- [x] Menu e seleção de fases
- [x] Progresso e estrelas salvos em `user://save.json`
- [x] Fundos temáticos, animações, efeitos e feedback de áudio
- [ ] Ícone e revisão final de acessibilidade
- [ ] Build Android (AAB) e teste fechado na Play Store
- [ ] Build iOS
