# MyGitScripts - Instruções para AI Coding Agents

Sistema de automação Git multi-aplicativo com backup automático no Google Drive. Scripts Bash executados no Windows via Git Bash.

## Arquitetura Central

**Princípio DRY**: Lógica genérica em `Comum/`, wrappers específicos em `Scripts_Para_XXX/`.

### Estrutura de Execução

```
Scripts_Para_FinCtl/commit.sh (wrapper)
  ↓ carrega config.sh (APP_NAME, REPOS)
  ↓ carrega Comum/funcoes_auxiliares.sh
  ↓ carrega Comum/git_operations.sh
  ↓ executa Comum/git_commit.sh (lógica genérica)
```

**Isolamento**: Scripts em `Scripts_Para_FinCtl/` afetam APENAS FinCtl. Scripts em `Scripts_Para_InvCtl/` afetam APENAS InvCtl.

### Módulos Compartilhados (`Comum/`)

- `config_base.sh`: Detecta máquina (hostname), Google Drive (inglês/português), define paths de backup
- `funcoes_auxiliares.sh`: Funções `do_backup_app()`, `do_backup_framework()`, `DeletaBkpMaisAntigo()` (mantém 4 backups)
- `git_operations.sh`: `validate_repo_structure()`, `git_safe_commit()`, `git_safe_merge()`, `ensure_developer_branch()`
- `git_commit.sh`, `git_merge_commit.sh`, `git_push.sh`, `git_pull.sh`: Lógica genérica de cada operação

### Configuração por Aplicativo

Cada `Scripts_Para_XXX/config.sh` define:
- `APP_NAME`: Nome do app (ex: "FinCtl", "InvCtl")
- `REPOS`: Array de `"nome|path"` (ex: `"FinCtl|C:/Applications_DSB/FinCtl"`)
- Carrega automaticamente `config_base.sh`

## Regras Críticas

### Branch Developer (Invariante)

**TODAS** as operações garantem retorno à branch `developer`:
- Após commit, merge, push, pull → `developer`
- Após ERRO → `ensure_developer_branch()` força retorno
- Implementado em `git_operations.sh::ensure_developer_branch()`

### Merge Fast-Forward Only

`git_safe_merge()` só aceita fast-forward (`developer` → `master`):
- ✅ Se `master` atrás de `developer`: merge permitido
- ❌ Se `master` divergiu: abort com erro (requer resolução manual)
- Validação: `git rev-list --count master..developer` vs `developer..master`

### Validações de Push (10 Checks)

Antes de push, `git_push.sh` valida:
1. Repositório existe
2. É Git válido (.git presente)
3. Branches `developer` e `master` existem
4. `master` sincronizada com `developer` (fast-forward)
5. Há commits não pushados em `developer`
6. Há commits não pushados em `master`
7. Working directory limpo (sem alterações)
8. Sem arquivos untracked
9. Remote `origin` configurado
10. Remoto acessível

## Sistema de Backup

### Destino

`{Google Drive}/Applications_DSB_Copias/{machine}/{AppName}/`
- `{machine}`: `dsb_asus` ou `administrator` (detectado via hostname)
- Cada app + `framework_dsb` tem pasta própria

### Nomenclatura

`{AppName}_YYYYMMDD_HHMMSS` (ex: `FinCtl_20251125_143022`)

### Retenção

Mantém **4 backups mais recentes** por pasta. `DeletaBkpMaisAntigo()` deleta 5º+ automaticamente.

### Quando Ocorre

- ✅ **Commit**: Após commitar (backup pós-alteração)
- ✅ **Merge**: Após merge developer→master (backup pós-produção)
- ✅ **Pull**: ANTES de puxar (backup de segurança pré-alteração)
- ❌ **Push**: Não faz backup (push não altera local)

## Padrões de Código

### Source de Módulos

Sempre carregar em ordem:
```bash
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/../Comum/funcoes_auxiliares.sh"
source "$SCRIPT_DIR/../Comum/git_operations.sh"
source "$SCRIPT_DIR/../Comum/git_commit.sh"  # ou outro script genérico
```

### Paths Unix no Windows

Usar `to_unix_path()` para compatibilidade Git Bash:
```bash
repo_path="$(to_unix_path "$path")"
run_git "$repo_path" status
```

### Logs

Usar `log()` para registrar operações:
```bash
log "== INÍCIO COMMIT =="
# operações...
log "== FIM COMMIT =="
```
Destino: `$HOME/dsb_git_scripts_{machine}.log`

## Adicionar Novo Aplicativo

1. Copiar `Scripts_Para_Game/` para `Scripts_Para_NovoApp/`
2. Editar `config.sh`: Alterar `APP_NAME` e array `REPOS`
3. Wrappers (`commit.sh`, `merge.sh`, `push.sh`, `pull.sh`) já funcionam automaticamente

Exemplo `config.sh`:
```bash
APP_NAME="NovoApp"
REPOS=(
  "NovoApp|C:/Applications_DSB/NovoApp"
  "backend|C:/Applications_DSB/framework_dsb/backend"
  "frontend|C:/Applications_DSB/framework_dsb/frontend"
)
```

## Convenções Específicas

- **Mensagens de commit**: Inclui timestamp UTC no formato `[YYYY-MM-DD HH:MM:SS UTC] mensagem`
- **Erro handling**: Scripts usam `set -eo pipefail` para interromper em erros
- **Validação prévia**: Sempre validar estrutura (`validate_repo_structure()`) antes de operar
- **Framework compartilhado**: `backend` e `frontend` são usados por todos os apps, backup separado em `framework_dsb/`

## Troubleshooting

- **"Configurações não foram carregadas"**: Wrapper não carregou `config.sh`. Executar wrapper, não script genérico diretamente.
- **"Merge não é fast-forward"**: `master` divergiu. Usar `git log --graph --oneline --all` para diagnosticar.
- **"Google Drive não encontrado"**: Verificar se montado em `G:/` (inglês ou português).
