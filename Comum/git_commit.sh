#!/usr/bin/env bash
set -eo pipefail

# =============================
# SCRIPT GENÉRICO - GIT COMMIT
# =============================
# Este script é GENÉRICO e pode ser usado por qualquer aplicativo
# Requer que config.sh tenha sido carregado antes com:
#   APP_NAME, REPOS, DEFAULT_BRANCH, BACKUP_DEST, BACKUP_BASE_NAME, BACKUP_SOURCES

# Validar que configurações necessárias foram carregadas
if [[ -z "${APP_NAME:-}" ]]; then
  echo "❌ ERRO: Configurações não foram carregadas!"
  echo "💡 Use o wrapper específico do aplicativo (ex: commit.sh)"
  exit 1
fi

# =============================
# Fluxo principal
# =============================
echo "========================================="
echo "   COMMIT (sem push) + BACKUP"
echo "   Aplicativo: $APP_NAME"
echo "   Branch: $DEFAULT_BRANCH"
echo "========================================="
echo

# Verificar se há algo para commitar em CADA repositório
echo "🔍 Verificando estrutura e alterações nos repositórios..."
echo
has_changes=false
total_repos=0
repos_with_changes=0
has_invalid_repos=false

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  repo_path="$(to_unix_path "$path")"
  total_repos=$((total_repos + 1))
  
  # Validar estrutura do repositório
  if ! validate_repo_structure "$name" "$repo_path"; then
    has_invalid_repos=true
    continue
  fi
  
  # Verificar status do repositório
  if ! porcelain=$(run_git "$repo_path" status --porcelain 2>/dev/null); then
    echo "❌ [$name] Erro ao verificar status"
    continue
  fi
  
  if [[ -n "$porcelain" ]]; then
    file_count=$(echo "$porcelain" | wc -l)
    echo "📝 [$name] $file_count arquivo(s) com alterações"
    has_changes=true
    repos_with_changes=$((repos_with_changes + 1))
  else
    echo "✅ [$name] Nenhuma alteração"
  fi
done

echo
echo "📊 Resumo: $total_repos repositório(s) verificado(s), $repos_with_changes com alterações"
echo

if [[ "$has_invalid_repos" == "true" ]]; then
  echo "❌ Há repositórios com estrutura inválida. Corrija antes de continuar."
  exit 1
fi

if [[ "$has_changes" == "false" ]]; then
  echo "✅ Nada a commitar. Operação concluída."
  exit 0
fi

# Commitar com timestamp automático
COMMIT_MSG="Atualização automática $(date +'%Y-%m-%d %H:%M:%S')"
echo "💾 Commitando alterações..."
echo

log "== INÍCIO COMMIT =="
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  git_safe_commit "$name" "$(to_unix_path "$path")" "$DEFAULT_BRANCH" "$COMMIT_MSG"
done
log "== FIM COMMIT =="

log "== INÍCIO BACKUP =="
# Backup do aplicativo específico
do_backup_app "$APP_NAME" "C:/Applications_DSB/${APP_NAME}" || true
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/${APP_NAME}" "${APP_NAME}"

# Backup do framework_dsb (compartilhado)
do_backup_framework || true
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/framework_dsb" "framework_dsb"
log "== FIM BACKUP =="

echo
echo "Operação concluída. Log em: $LOG_FILE"
