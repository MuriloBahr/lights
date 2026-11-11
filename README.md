# Lights

Lights é um jogo de lógica para celulares, feito com Godot 4.7 e GDScript. Em cada fase, os toques mudam o estado de algumas lâmpadas. O objetivo é apagar todas ou, nas fases de Pintura, formar o desenho indicado.

## Como jogar

- Toque em uma lâmpada para alternar seu estado e o das lâmpadas afetadas pela regra da fase.
- Apague todas as lâmpadas ou forme o desenho de referência para concluir a fase.
- Use **Desfazer** para reverter a última jogada ou **Reiniciar** para começar de novo.
- **Dica** destaca uma jogada da solução. A quantidade disponível aparece junto ao botão e é restaurada ao reiniciar.
- Resolver com poucos toques rende até três lâmpadas de recompensa. As fases são desbloqueadas em sequência.

## Mundos e fases

O jogo tem 90 fases em sete mundos, nesta ordem de progressão:

1. **Clássico** — o toque afeta a lâmpada selecionada e as vizinhas em cruz.
2. **Pintura** — alterne as luzes até formar o desenho mostrado.
3. **Diagonais** — o toque afeta as diagonais.
4. **Formas** — algumas posições da grade não têm lâmpadas.
5. **Mistura** — alterna padrões de cruz, diagonais e tabuleiros com formatos diferentes.
6. **Espelho** — o toque também ecoa na posição oposta do tabuleiro.
7. **Raio** — o toque afeta a fileira e a coluna.

Ao entrar em cada mundo pela primeira vez, uma demonstração interativa permite experimentar a regra. Pintura tem 24 fases. A progressão usa grades de até 4×4 e soluções de no máximo três toques; as seis primeiras fases de Clássico são resolvidas com um toque.

## Recursos

- Fundos pastel com detalhes próprios por fase, lâmpadas com carinhas, animações e temas visuais desbloqueáveis.
- Prévia das lâmpadas afetadas antes de confirmar a jogada; tocar fora cancela a seleção.
- Nas quatro primeiras fases de cada mundo, as lâmpadas afetadas pulsam para ensinar a regra visualmente.
- Transição animada ao iniciar o jogo, com lâmpadas subindo pela tela.
- Música, efeitos sonoros e vibração, com controles de preferência nas configurações.
- Tutoriais interativos por mundo e um guia **Como jogar** nas configurações.
- Navegação separada entre **Fases**, **Missões** e **Temas** para manter cada tela mais simples.
- Tela de **Missões** com um tabuleiro diário e uma tarefa simples de fase normal. As missões aceitam dicas e tentativas livres e dão lâmpadas bônus uma vez por dia.
- Lâmpadas de fase continuam registrando o melhor resultado; as bônus se acumulam e desbloqueiam temas de fundo na tela **Temas**, sem consumir estrelas.
- Progresso, recompensas de missão, temas selecionados, configurações e conclusão diária são salvos em `user://save.json`.
- Layout responsivo para telas estreitas e altas, com painéis de ajuda roláveis e seleção de fases compatível com toque.
- Orientação vertical configurada para celulares Android e iOS.

## Tecnologias e estrutura

- **Godot 4.7** — engine e interface do jogo.
- **GDScript** — lógica, telas, animações e áudio.
- **JSON** — dados das fases e arquivo local de progresso.
- **Python 3** — ferramenta opcional para regenerar as fases.

```text
assets/
  icons/                 ícones do projeto e do aplicativo Android
  music/                 música do jogo
  sfx/                   efeitos sonoros
data/
  levels.json            mundos e fases
scenes/
  menu.tscn              menu principal
  level_select.tscn      seleção de fases
  missions.tscn          missões diárias
  themes.tscn            coleção de temas visuais
  game.tscn              tabuleiro
scripts/
  board.gd               regras e estado do tabuleiro, sem dependência da interface
  game.gd                tela e fluxo da partida
  level_select.gd        seleção e progresso das fases
  state.gd               dados compartilhados, salvamento e transições
  bulb.gd                lâmpadas, animações e desenho
  world_backdrop.gd      fundos temáticos
  goal_preview.gd        miniatura do desenho-alvo
  how_to_panel.gd        demonstrações interativas
  settings_panel.gd      configurações
  menu.gd                tela inicial e animação de início
  missions.gd            missões e recompensas diárias
  themes.gd              coleção e seleção de temas visuais
  gear_button.gd         botão de configurações
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

O gerador cria fases solucionáveis e grava a quantidade mínima de jogadas e uma sequência de solução. Cada fase inclui `id`, `world`, `size`, `grid`, `par` e `solution`. `shape`, `mask`, `effect`, `goal` e `hint` são opcionais. `goal` descreve o desenho-alvo das fases de Pintura.

## Exportar para Android

O Android Studio fornece o Android SDK, mas a exportação do jogo é feita pelo Godot:

1. Instale o Godot 4.7 e os **Export Templates** da mesma versão.
2. No Android Studio, instale pelo **SDK Manager** os componentes exigidos pelo Godot, incluindo Android SDK Platform, Build-Tools, Platform-Tools e Command-line Tools.
3. No Godot, configure os caminhos do Java SDK e do Android SDK em **Editor → Editor Settings → Export → Android**.
4. Abra **Project → Export**, crie ou selecione o preset Android e configure o identificador único do pacote e a assinatura.
5. Exporte um APK para instalar e testar no celular. Para publicação na Play Store, configure uma chave de release e exporte um AAB.

Depois de mudar o projeto, é necessário exportar novamente e instalar a nova build no aparelho; a cópia já instalada não se atualiza sozinha. Confirme a orientação vertical em uma build Android, pois a configuração do projeto só entra em vigor na próxima exportação.

## Dados e arquitetura

`data/levels.json` é a fonte dos mundos e das fases. A grade é representada em ordem de linhas, com `1` para lâmpada acesa e `0` para apagada. `par` indica o mínimo de toques; `solution` contém os índices das lâmpadas da solução. `goal` define o desenho-alvo, `mask` define quais posições têm lâmpadas, `effect` pode ser `mirror` ou `line`, e `shape` define o padrão de vizinhança (`plus` ou `x`).

`Board` mantém a lógica separada da interface e emite os sinais `changed` e `solved`. A tela de jogo reage a esses sinais para atualizar as lâmpadas, efeitos e progresso. O progresso fica no armazenamento local do dispositivo, não no repositório.

## Pendências antes de publicar

- Testar a jogabilidade, orientação, áreas seguras e desempenho em diferentes celulares.
- Revisar acessibilidade, ícones e informações da ficha da loja.
- Preparar e testar a build de release assinada; uma build de desenvolvimento não é adequada para publicação.
- Fazer o processo de exportação e testes para iOS separadamente em um ambiente compatível.
