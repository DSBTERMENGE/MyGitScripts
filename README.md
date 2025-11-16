# MyGitScripts - Sistema de Automação Git

Sistema centralizado de scripts Bash para automação de operações Git (commit, merge, push, pull) com backup automático no Google Drive.

## 📁 Estrutura do Projeto

```
Scripts_Para_Git/
├── Comum/                          # Scripts e funções compartilhadas
│   ├── config_base.sh              # Configurações base (machine ID, Google Drive)
│   ├── funcoes_auxiliares.sh       # Funções utilitárias e backup
│   ├── git_operations.sh           # Operações Git com validações
│   ├── git_commit.sh               # Script genérico de commit
│   ├── git_merge_commit.sh         # Script genérico de merge
│   ├── git_push.sh                 # Script genérico de push
│   └── git_pull.sh                 # Script genérico de pull
│
├── Scripts_Para_FinCtl/            # Scripts para aplicativo FinCtl
│   ├── config.sh                   # Configurações específicas do FinCtl
│   ├── commit.sh                   # Wrapper para commit
│   ├── merge.sh                    # Wrapper para merge
│   ├── push.sh                     # Wrapper para push
│   └── pull.sh                     # Wrapper para pull
│
├── Scripts_Para_InvCtl/            # Scripts para aplicativo InvCtl
│   └── [mesma estrutura]
│
├── Scripts_Para_Game/              # Scripts para aplicativo Game
│   └── [mesma estrutura]
│
└── Scripts_Para_Applications_DSB_Umbrella/  # Scripts para Umbrella (a criar)
```

## 🎯 Como Funciona

### Arquitetura

1. **Pasta `Comum/`**: Contém toda a lógica genérica compartilhada por todos os aplicativos
2. **Pastas `Scripts_Para_XXX/`**: Contém apenas wrappers leves que configuram e chamam os scripts genéricos
3. **Cada aplicativo é independente**: Executar script em uma pasta afeta APENAS aquele aplicativo

### Fluxo de Execução

```
Scripts_Para_FinCtl/commit.sh
    ↓
Carrega config.sh (FinCtl)
    ↓
Carrega módulos compartilhados (Comum/)
    ↓
Executa Comum/git_commit.sh
    ↓
Commita nos repositórios definidos em REPOS:
    - FinCtl
    - backend
    - frontend
    ↓
Faz backup:
    - FinCtl → Google Drive/{machine}/FinCtl/
    - framework_dsb → Google Drive/{machine}/framework_dsb/
```

## 🚀 Como Usar

### 1. Commit (branch developer)

```bash
cd C:/Scripts_Para_Git/Scripts_Para_FinCtl
./commit.sh
```

**O que faz:**
- Commita alterações na branch `developer` nos 3 repositórios (FinCtl, backend, frontend)
- Cria backup com timestamp no Google Drive
- Mantém últimos 4 backups (deleta mais antigos)
- SEMPRE retorna para branch developer ao final

### 2. Merge (developer → master)

```bash
cd C:/Scripts_Para_Git/Scripts_Para_FinCtl
./merge.sh
```

**O que faz:**
- Commita mudanças pendentes em developer (se houver)
- Faz merge fast-forward de developer para master
- Cria backup após merge
- SEMPRE retorna para branch developer

### 3. Push (enviar para GitHub)

```bash
cd C:/Scripts_Para_Git/Scripts_Para_FinCtl
./push.sh
```

**O que faz:**
- Valida estado dos repositórios (10 verificações de segurança)
- Push da branch developer
- Push da branch master
- SEMPRE retorna para branch developer
- NÃO faz backup (push não altera local)

### 4. Pull (atualizar do GitHub)

```bash
cd C:/Scripts_Para_Git/Scripts_Para_FinCtl
./pull.sh
```

**O que faz:**
- **FASE 1**: Verifica se pull é necessário (sem backup)
- **FASE 2**: Se necessário, cria backup DE SEGURANÇA antes de puxar
- **FASE 3**: Executa pull (fast-forward quando possível, merge se necessário)
- SEMPRE retorna para branch developer

## 🔧 Configuração

### Repositórios Suportados (em `config.sh`)

Cada aplicativo define seus repositórios no array `REPOS`:

```bash
# Scripts_Para_FinCtl/config.sh
APP_NAME="FinCtl"
REPOS=(
  "FinCtl|C:/Applications_DSB/FinCtl"
  "backend|C:/Applications_DSB/framework_dsb/backend"
  "frontend|C:/Applications_DSB/framework_dsb/frontend"
)
```

**Importante:** Quando você executa um script em `Scripts_Para_FinCtl/`, ele trabalha APENAS com esses 3 repos. NÃO afeta InvCtl, Game ou outros.

### Máquinas Detectadas Automaticamente

O sistema detecta em qual máquina está rodando:
- `dsb_asus` (hostname: DSB_ASUS)
- `administrator` (hostname: DESKTOP-*)

Backups vão para: `{Google Drive}/Applications_DSB_Copias/{machine}/`

### Google Drive

Detecta automaticamente:
- `G:/My Drive/` (inglês)
- `G:/Meu Drive/` (português)

## 📦 Sistema de Backup

### Estrutura no Google Drive

```
G:/My Drive/Applications_DSB_Copias/
├── dsb_asus/
│   ├── FinCtl/
│   │   ├── FinCtl_20251116_120000/
│   │   ├── FinCtl_20251116_130000/
│   │   ├── FinCtl_20251116_140000/
│   │   └── FinCtl_20251116_150000/  (máximo 4)
│   │
│   ├── framework_dsb/
│   │   ├── framework_dsb_20251116_120000/
│   │   └── ...
│   │
│   ├── InvCtl/
│   └── Game/
│
└── administrator/
    └── [mesma estrutura]
```

### Retenção de Backups

- **Limite**: 4 backups mais recentes por pasta
- **Nomenclatura**: `{AppName}_YYYYMMDD_HHMMSS`
- **Limpeza automática**: Ao criar 5º backup, deleta o mais antigo
- **Independente**: Cada subpasta (FinCtl, framework_dsb, etc) mantém seus próprios 4 backups

### Quando Faz Backup

✅ **Commit**: Backup após commitar
✅ **Merge**: Backup após merge
✅ **Pull**: Backup ANTES de puxar (segurança)
❌ **Push**: NÃO faz backup (push não altera arquivos locais)

## 🔒 Regras de Segurança

### Branch Developer (Sempre Retorna)

**TODAS** as operações garantem que você termina na branch `developer`:
- Após commit → developer
- Após merge → developer
- Após push → developer
- Após pull → developer
- Após ERRO → developer

### Validações de Push

Antes de fazer push, o sistema valida:
1. ✅ Repositório existe
2. ✅ Está em repositório Git válido
3. ✅ Branches developer e master existem
4. ✅ Branch master está sincronizada com developer
5. ✅ Commits não pushados em developer
6. ✅ Commits não pushados em master
7. ✅ Sem alterações não commitadas
8. ✅ Sem arquivos untracked
9. ✅ Remote origin configurado
10. ✅ Remoto acessível

### Merge Fast-Forward Only

O sistema **APENAS** faz merge fast-forward (developer → master):
- ✅ Se master está atrás de developer: merge permitido
- ❌ Se master divergiu: erro e abort (requer intervenção manual)

## 📋 Logs

Todas as operações são registradas em:
```
C:/Applications_DSB/{AppName}/logs/git_operations.log
```

Formato: `[YYYY-MM-DD HH:MM:SS] mensagem`

## 🔄 Workflow Completo (Exemplo)

### Dia a dia no FinCtl:

```bash
# 1. Trabalha no código, faz alterações...

# 2. Commit na developer
cd C:/Scripts_Para_Git/Scripts_Para_FinCtl
./commit.sh
# Digite mensagem: "Implementa validação de formulário"

# 3. Testa, valida...

# 4. Merge para master (produção)
./merge.sh

# 5. Push para GitHub
./push.sh

# 6. No outro computador, pega atualizações
cd C:/Scripts_Para_Git/Scripts_Para_FinCtl
./pull.sh
```

## 🆕 Adicionar Novo Aplicativo

Para criar scripts para um novo aplicativo `MeuApp`:

1. **Copie pasta de exemplo:**
```bash
cp -r Scripts_Para_Game Scripts_Para_MeuApp
```

2. **Edite `config.sh`:**
```bash
APP_NAME="MeuApp"
REPOS=(
  "MeuApp|C:/Applications_DSB/MeuApp"
  "backend|C:/Applications_DSB/framework_dsb/backend"
  "frontend|C:/Applications_DSB/framework_dsb/frontend"
)
DB_PATH="C:/Applications_DSB/MeuApp/data"
DB_FILES="meuapp.db"
```

3. **Wrappers (commit.sh, merge.sh, push.sh, pull.sh) já funcionam automaticamente!**

## 🔧 Manutenção

### Sincronizar Scripts Entre Máquinas

Este próprio repositório `MyGitScripts` está versionado no GitHub:

```bash
# Máquina 1: Faz alterações e envia
cd C:/Scripts_Para_Git
git add .
git commit -m "Atualiza scripts"
git push

# Máquina 2: Recebe alterações
cd C:/Scripts_Para_Git
git pull
```

### Recuperar Backup

Se precisar restaurar um backup:

```bash
# Listar backups disponíveis
ls "G:/My Drive/Applications_DSB_Copias/dsb_asus/FinCtl/"

# Copiar backup desejado
cp -r "G:/My Drive/.../FinCtl_20251116_120000" "C:/Applications_DSB/FinCtl_RECUPERADO"
```

## ⚠️ Importante

1. **Nunca execute scripts de uma pasta para afetar outro aplicativo**
   - Scripts em `Scripts_Para_FinCtl/` trabalham APENAS com FinCtl
   - Scripts em `Scripts_Para_InvCtl/` trabalham APENAS com InvCtl

2. **Backend e frontend são compartilhados**
   - Todos os apps (FinCtl, InvCtl, Game) usam o mesmo framework_dsb
   - Backups do framework_dsb acumulam commits de todos os apps

3. **Sempre use Git Bash no Windows**
   - Scripts são Bash, não PowerShell
   - Use: `cd /c/Scripts_Para_Git/...`

4. **Google Drive deve estar sincronizado**
   - Backups vão para Google Drive
   - Certifique-se que pasta está acessível

## 📞 Troubleshooting

### "fatal: not a git repository"
- Você está na pasta errada
- Navegue para `C:/Scripts_Para_Git/Scripts_Para_XXX/`

### "Configurações não foram carregadas"
- Não execute scripts genéricos diretamente
- Use os wrappers (commit.sh, merge.sh, etc)

### "Falha no backup"
- Verifique se Google Drive está sincronizado
- Verifique espaço disponível no Drive

### "Merge não é fast-forward"
- Master divergiu de developer
- Requer resolução manual de conflitos
- Use `git log --graph --oneline --all` para ver divergência

---

**Autor:** Sistema desenvolvido para gerenciar múltiplos aplicativos DSB  
**Repositório:** https://github.com/DSBTERMENGE/MyGitScripts  
**Última Atualização:** 2025-11-16
