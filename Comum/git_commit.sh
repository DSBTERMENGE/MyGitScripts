#!/usr/bin/env bash
set -euo pipefail

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
read -rp "Digite a mensagem do commit: " COMMIT_MSG
if [[ -z "$COMMIT_MSG" ]]; then
  COMMIT_MSG="Atualização automática"
fi

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
