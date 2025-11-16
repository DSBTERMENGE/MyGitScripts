#!/usr/bin/env bash

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

process_repo() {
  local name="$1"
  local raw_path="$2"
  local message="$3"
  local path
  path="$(to_unix_path "$raw_path")"
  
  echo "=== [$name] ==="
  [[ -d "$path/.git" ]] || { echo "[ERRO] Não é repositório Git: $path"; return 0; }

  # 1) Commit em developer (se houver mudanças)
  git_safe_commit "$name" "$path" "$DEFAULT_BRANCH" "$message"

  # 2) Merge para production
  git_safe_merge "$name" "$path" "$DEFAULT_BRANCH" "$PRODUCTION_BRANCH"
}

echo "========================================="
echo " DEV: commit (se houver) | MASTER: fast-forward"
echo " Aplicativo: $APP_NAME"
echo "========================================="
echo
read -rp "Mensagem do commit (developer): " COMMIT_MSG
[[ -z "$COMMIT_MSG" ]] && COMMIT_MSG="Atualização automática"

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
