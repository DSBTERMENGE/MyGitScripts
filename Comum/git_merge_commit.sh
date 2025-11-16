#!/usr/bin/env bash
set -eo pipefail

# =============================
# SCRIPT GENÉRICO - GIT MERGE COMMIT
# =============================
# Este script é GENÉRICO e pode ser usado por qualquer aplicativo
# Política: master só avança por fast-forward a partir de developer.
# Se master tiver commits próprios (ahead_master > 0), NÃO faz merge.

# Validar que configurações necessárias foram carregadas
if [[ -z "${APP_NAME:-}" ]]; then
  echo "❌ ERRO: Configurações não foram carregadas!"
  echo "💡 Use o wrapper específico do aplicativo (ex: merge.sh)"
  exit 1
fi

echo "========================================="
echo " DEV: commit (se houver) | MASTER: fast-forward"
echo " Aplicativo: $APP_NAME"
echo "========================================="
echo

# Verificar se há algo para fazer (commits pendentes ou merge necessário)
echo "🔍 Verificando estrutura e status dos repositórios..."
echo
has_work=false
total_repos=0
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
  
  # Verificar alterações não commitadas
  porcelain=$(run_git "$repo_path" status --porcelain 2>/dev/null || true)
  
  if [[ -n "$porcelain" ]]; then
    file_count=$(echo "$porcelain" | wc -l)
    echo "📝 [$name] $file_count arquivo(s) para commitar"
    has_work=true
  else
    # Verificar se há diferença entre developer e master
    ahead_master=$(run_git "$repo_path" rev-list --count "$PRODUCTION_BRANCH..$DEFAULT_BRANCH" 2>/dev/null || echo "0")
    if [[ "$ahead_master" -gt 0 ]]; then
      echo "🔄 [$name] $ahead_master commit(s) para merge em $PRODUCTION_BRANCH"
      has_work=true
    else
      echo "✅ [$name] Sincronizado"
    fi
  fi
done

echo

if [[ "$has_invalid_repos" == "true" ]]; then
  echo "❌ Há repositórios com estrutura inválida. Corrija antes de continuar."
  exit 1
fi

if [[ "$has_work" == "false" ]]; then
  echo "✅ Nada a fazer. Todos os repositórios estão sincronizados."
  exit 0
fi

# Prosseguir com commit e merge
COMMIT_MSG="Atualização automática $(date +'%Y-%m-%d %H:%M:%S')"
echo "💾 Processando commits e merges..."
echo

process_repo() {
  local name="$1"
  local raw_path="$2"
  local message="$3"
  local path
  path="$(to_unix_path "$raw_path")"
  
  echo "=== [$name] ==="
  
  # Validação já foi feita antes, apenas processar
  # 1) Commit em developer (se houver mudanças)
  git_safe_commit "$name" "$path" "$DEFAULT_BRANCH" "$message"

  # 2) Merge para production
  git_safe_merge "$name" "$path" "$DEFAULT_BRANCH" "$PRODUCTION_BRANCH"
}

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  process_repo "$name" "$path" "$COMMIT_MSG"
done

echo
log "== FIM MERGE =="

log "== INÍCIO BACKUP =="
# Backup do aplicativo específico
do_backup_app "$APP_NAME" "C:/Applications_DSB/${APP_NAME}" || true
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/${APP_NAME}" "${APP_NAME}"

# Backup do framework_dsb (compartilhado)
do_backup_framework || true
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/framework_dsb" "framework_dsb"
log "== FIM BACKUP =="
echo
echo "Concluído em $(ts)"
