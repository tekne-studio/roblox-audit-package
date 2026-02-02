# CLAUDE.md - Roblox Audit Package

Este arquivo guia o Claude Code nas interações com o projeto roblox-audit.

## REGRA CRÍTICA: RELEASES E TAGS AUTOMÁTICAS

**Tags e releases são gerados AUTOMATICAMENTE pelo sistema de CI/CD**
- NÃO criar tags manualmente com `git tag`
- NÃO fazer push de tags com `git push --tags`
- O sistema de auto-release detecta mudanças de versão no `rokit.toml`
- Quando a versão é atualizada no campo `version`, o CI/CD automaticamente:
  - Cria a tag correspondente (ex: v0.0.13)
  - Gera o changelog baseado nos commits convencionais
  - Publica o release no GitHub
  - Disponibiliza o pacote via Rokit
- Apenas faça commit e push das mudanças normalmente com `git push`

## Visão Geral

O **roblox-audit** é uma ferramenta de auditoria e análise de dependências para projetos Roblox/Rojo escritos em Luau.

### Características
- Análise de tipos com luau-lsp
- Linting com Selene
- Verificação de formatação com StyLua
- Detecção de dependências circulares
- Geração de grafos de dependências
- Auto-instalação de dependências via Rokit

## Estrutura do Projeto

```
roblox-audit-package/
├── src/
│   ├── audit.lua                    # Script principal
│   ├── analyze-dependencies.lua     # Análise de dependências
│   └── visualize-dependencies.lua   # Geração de grafos
├── dist/
│   └── audit-bundled.lua           # Versão bundled (gerada automaticamente)
├── rokit.toml                       # Configuração do pacote Rokit
├── .darklua.json5                   # Configuração do bundler
└── build.sh                         # Script de build
```

## Workflow de Desenvolvimento

### 1. Fazer mudanças no código

Edite os arquivos em `src/`:
- `audit.lua` - lógica principal
- `analyze-dependencies.lua` - detecção de circular deps
- `visualize-dependencies.lua` - geração de grafos DOT/SVG

### 2. Atualizar versão

Edite `rokit.toml` e atualize o campo `version`:
```toml
[package]
version = "0.0.14"  # Incrementar versão
```

### 3. Buildar a versão bundled

```bash
./build.sh
```

Isso gera `dist/audit-bundled.lua` usando darklua.

### 4. Commitar e fazer push

```bash
git add .
git commit -m "feat: descrição da mudança"
git push
```

O sistema de auto-release detectará a mudança de versão e:
- Criará a tag `v0.0.14`
- Gerará o changelog
- Publicará o release

**NÃO criar tags manualmente!**

## Convenções de Commits

Use commits convencionais para geração automática de changelog:

- `feat: ...` - Nova funcionalidade
- `fix: ...` - Correção de bug
- `docs: ...` - Apenas documentação
- `refactor: ...` - Refatoração sem mudança de comportamento
- `chore: ...` - Manutenção (build, deps, etc)

## Testes Locais

Para testar localmente antes de publicar:

```bash
cd /Users/marlus/dev/__REPOS/roblox-mount-roraima-obby
lua roblox-audit-package/dist/audit-bundled.lua
```

Ou use o roblox-audit instalado via Rokit:

```bash
rokit add tekne-studio/roblox-audit@<version>
roblox-audit
```

## Dependências

O roblox-audit depende de:
- `luau-lsp` - Type checking
- `selene` - Linting
- `stylua` - Formatação

Essas dependências são **auto-instaladas** quando o audit executa pela primeira vez em um projeto (via função `ensureRokitTools()`).
