# Arquitetura do projeto

Lights é um projeto Godot organizado por responsabilidade. Cenas montam as telas; scripts de tela coordenam a interface; lógica do tabuleiro e progresso ficam em módulos compartilhados.

## Pastas

- `scenes/` contém as cenas de entrada de cada tela.
- `scripts/screens/` contém os controladores das telas principais.
- `scripts/gameplay/` contém as regras do tabuleiro, peças e fluxo de uma partida.
- `scripts/ui/` contém componentes e painéis reutilizados pelas telas.
- `scripts/visuals/` contém desenho de fundos e personagens.
- `scripts/audio/` contém reprodução de música, efeitos sonoros e vibração.
- `scripts/core/` contém paleta e utilitários de interface sem estado de jogo.
- `scripts/autoload/` contém o nó global `State`, responsável por carregar dados, persistir progresso e coordenar transições.
- `data/` contém conteúdo editável do jogo, atualmente as fases em JSON.
- `assets/` contém recursos importados pelo Godot.
- `tools/` contém ferramentas de desenvolvimento que não são necessárias para executar o jogo.
- `docs/` contém documentação técnica do projeto.

## Fluxo principal

1. `State` carrega `data/levels.json` e restaura o progresso de `user://save.json`.
2. Uma cena em `scenes/` instancia o controlador correspondente em `scripts/screens/` ou `scripts/gameplay/`.
3. A tela de jogo envia as jogadas ao `Board`; o tabuleiro emite sinais quando muda ou é resolvido.
4. `State` grava estrelas, missões, temas, trilhas selecionadas e configurações.
5. Componentes visuais e de interface apresentam os dados sem duplicar as regras do tabuleiro.

## Regras para novas mudanças

- Scripts de tela ficam em `scripts/screens/`; regras puras de jogo ficam em `scripts/gameplay/`.
- Componentes reutilizáveis ficam em `scripts/ui/`, efeitos de desenho em `scripts/visuals/` e áudio em `scripts/audio/`.
- Listas roláveis usam `TouchScrollContainer` para manter o gesto de arraste e a inércia consistentes entre telas.
- Quando um arquivo Godot for movido ou renomeado, atualizar os caminhos em `.tscn`, `project.godot`, documentação e recursos que o carreguem explicitamente. Manter junto o arquivo `.uid`.
- Não colocar estado de partida dentro de componentes visuais. Persistência e dados compartilhados passam pelo `State`.
- Conteúdo de fases permanece em JSON; ferramentas em `tools/` podem gerar esses arquivos, mas o jogo não deve depender do Python em execução.
- Nomes de arquivos e pastas usam `snake_case` e devem descrever a responsabilidade do recurso.

## Próxima etapa de modularização

Os controladores `game.gd`, `level_select.gd`, `themes.gd`, `world_backdrop.gd` e `boss_portrait.gd` ainda concentram bastante código. Alterações futuras devem extrair responsabilidades em unidades pequenas, preservando comportamento e validando cada extração antes de seguir para a próxima.
