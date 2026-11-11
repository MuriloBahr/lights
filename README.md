# Lights

Lights é um jogo de lógica feito com Godot 4.7 e GDScript. O objetivo é apagar todas as lâmpadas de cada fase usando o menor número de toques possível. O projeto está pensado para celulares, com orientação vertical e interface que se adapta a diferentes tamanhos de tela.

## Como jogar

- Toque em uma lâmpada para alternar seu estado e o das lâmpadas afetadas pela regra do mundo.
- Apague todas as lâmpadas para concluir a fase.
- Use **Desfazer** para reverter a última jogada ou **Reiniciar** para começar de novo.
- **Dica** pulsa uma jogada da solução. Cada fase oferece uma dica por toque mínimo (`par`); dicas não usadas não são gastas e reiniciar restaura a quantidade.
- Tente resolver com poucos toques para ganhar até três lâmpadas de recompensa. As fases são desbloqueadas em sequência.

## Mundos e fases

O jogo tem 90 fases em sete mundos, com regras e identidade visual próprias:

1. **Clássico** — o toque afeta a lâmpada selecionada e as vizinhas em cruz.
2. **Diagonais** — o toque afeta as diagonais.
3. **Formas** — algumas posições da grade não têm lâmpadas.
4. **Mistura** — combina regras, formas e tamanhos de grade.
5. **Espelho** — o toque também ecoa na posição oposta do tabuleiro.
6. **Raio** — o toque afeta a fileira e a coluna.
7. **Pintura** — acenda e apague luzes para formar o desenho mostrado.

Ao entrar em um mundo pela primeira vez, uma demonstração interativa apresenta sua regra. Pintura agora tem 24 fases, com mais desenhos para montar. A progressão continua acolhedora: as fases usam grades de até 4×4 e soluções de no máximo três toques. As primeiras fases do mundo Clássico ensinam a regra com uma jogada; depois, novas regras e formas aparecem em tabuleiros pequenos.

## Recursos

- Fundos temáticos por mundo, lâmpadas coloridas, animações e efeitos visuais ao jogar, receber uma dica e concluir uma fase.
- Música, efeitos sonoros e vibração, com controles de preferência nas configurações.
- Desafio diário sem cronômetro. A conclusão do dia é salva separadamente e não altera o progresso das fases normais.
- Progresso, recompensas, configurações e conclusão diária salvos localmente em `user://save.json`.
- Layout responsivo para telas estreitas e altas: grade, botões, painéis e seleção de fases ajustam suas dimensões; painéis de ajuda podem rolar.
- Orientação vertical configurada para celulares Android e iOS.

## Tecnologias e estrutura

- **Godot 4.7** — engine e interface do jogo.
- **GDScript** — lógica, telas, animações e áudio.
- **JSON** — dados das fases e arquivo local de progresso.
- **Python 3** — ferramenta opcional para regenerar as fases.

```text
assets/
  music/                 música do jogo
  sfx/                   efeitos sonoros
data/
  levels.json            mundos e fases
scenes/
  menu.tscn              menu principal
  level_select.tscn      seleção de fases
  game.tscn              tabuleiro
scripts/
  board.gd               regras e estado do tabuleiro, sem dependência da interface
  game.gd                tela e fluxo da partida
  level_select.gd        seleção, progresso e desafio diário
  state.gd               dados compartilhados, salvamento e transições
  bulb.gd                lâmpadas, animações e desenho
  world_backdrop.gd      fundos temáticos
  how_to_panel.gd        demonstrações interativas
  settings_panel.gd      configurações
  win_panel.gd           resultado da fase
  sfx.gd                 música, efeitos sonoros e vibração
  ui.gd                  elementos reutilizáveis de interface
  pallete.gd             cores do jogo
tools/
  generate_levels.py     gerador opcional de fases
project.godot            configurações do projeto e da tela
```

## Executar no computador

1. Instale o Godot 4.7 e abra a pasta do projeto no editor.
2. Importe os recursos quando solicitado.
3. Execute o projeto com **F6** para a cena atual ou **F5** para iniciar pela cena principal.

Python não é necessário para executar o jogo. Para regenerar `data/levels.json` após alterar `tools/generate_levels.py`, rode na raiz do projeto:

```powershell
python tools\generate_levels.py
```

O gerador parte de uma grade apagada, cria fases solucionáveis e grava a quantidade mínima de jogadas e uma sequência de solução. O formato de cada fase inclui `id`, `world`, `size`, `grid`, `par` e `solution`; `shape`, `mask` e `effect` são opcionais.

## Exportar para Android

O Android Studio fornece o Android SDK, mas a exportação do jogo é feita pelo Godot:

1. Instale o Godot 4.7 e os **Export Templates** da mesma versão.
2. No Android Studio, instale pelo **SDK Manager** os componentes exigidos pelo Godot, incluindo Android SDK Platform, Build-Tools, Platform-Tools e Command-line Tools.
3. No Godot, configure os caminhos do Java SDK e do Android SDK em **Editor → Editor Settings → Export → Android**.
4. Abra **Project → Export**, crie ou selecione o preset Android e configure o identificador único do pacote e a assinatura.
5. Exporte um APK para instalar e testar no celular. Para publicação na Play Store, configure uma chave de release e exporte um AAB.

Depois de mudar o projeto, é necessário exportar novamente e instalar a nova build no aparelho; a cópia já instalada não se atualiza sozinha. Confirme a orientação vertical em uma build Android, pois a configuração do projeto só entra em vigor na próxima exportação.

## Dados e arquitetura

`data/levels.json` é a fonte dos mundos e das fases. A grade é representada em ordem de linhas, com `1` para lâmpada acesa e `0` para apagada. `par` indica o mínimo de toques; `solution` contém índices de lâmpadas que resolvem a fase. Efeitos especiais podem ser descritos por `effect` (`mirror` ou `line`), e `shape` define o padrão de vizinhança (`plus` ou `x`).

`Board` mantém a lógica separada da interface e emite os sinais `changed` e `solved`. A tela de jogo reage a esses sinais para atualizar as lâmpadas, efeitos e progresso. O progresso fica no armazenamento local do dispositivo, não no repositório.

## Pendências antes de publicar

- Testar a jogabilidade, orientação, áreas seguras e desempenho em diferentes celulares.
- Revisar acessibilidade, ícones e informações da ficha da loja.
- Preparar e testar a build de release assinada; uma build de desenvolvimento não é adequada para publicação.
- Fazer o processo de exportação e testes para iOS separadamente em um ambiente compatível.
