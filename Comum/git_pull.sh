#!/usr/bin/env bash

# =============================
# SCRIPT GENÉRICO - GIT PULL
# =============================
# Este script é GENÉRICO e pode ser usado por qualquer aplicativo

# Validar que configurações necessárias foram carregadas
if [[ -z "${APP_NAME:-}" ]]; then
  echo "❌ ERRO: Configurações não foram carregadas!"
  echo "💡 Use o wrapper específico do aplicativo (ex: pull.sh)"
  exit 1
fi

echo "========================================="
echo "   PULL (atualizar do GitHub)"
echo "   Aplicativo: $APP_NAME"
echo "========================================="
echo

# Validar estrutura de todos os repositórios primeiro
echo "🔍 Validando estrutura dos repositórios..."
echo
has_invalid_repos=false

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  repo_path="$(to_unix_path "$path")"
  
  if ! validate_repo_structure "$name" "$repo_path"; then
    has_invalid_repos=true
  fi
done

if [[ "$has_invalid_repos" == "true" ]]; then
  echo
  echo "❌ Há repositórios com estrutura inválida. Corrija antes de fazer pull."
  exit 1
fi

echo "✅ Estrutura validada"
echo

# BACKUP DE SEGURANÇA ANTES DO PULL
echo "== BACKUP DE SEGURANÇA =="
echo "📦 Criando backup antes de atualizar do GitHub..."
echo

log "== INÍCIO BACKUP PRÉ-PULL =="
# Backup do aplicativo específico
if ! do_backup_app "$APP_NAME" "C:/Applications_DSB/${APP_NAME}"; then
  echo "❌ Falha no backup do aplicativo"
  echo "⚠️  Recomendado fazer backup manual antes de continuar"
  read -rp "Continuar mesmo assim? (s/N): " resposta
  if [[ ! "$resposta" =~ ^[sS]$ ]]; then
    echo "Operação cancelada pelo usuário"
    exit 1
  fi
else
  echo "✅ Backup do aplicativo concluído"
fi

# Backup do framework_dsb (compartilhado)
if ! do_backup_framework; then
  echo "⚠️  Falha no backup do framework"
else
  echo "✅ Backup do framework concluído"
fi

# Limpeza dos backups antigos
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/${APP_NAME}" "${APP_NAME}"
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/framework_dsb" "framework_dsb"
log "== FIM BACKUP PRÉ-PULL =="

echo
echo "✅ Backup de segurança concluído"
echo

# Executar pull nos repositórios
echo "== EXECUTANDO PULL (DEVELOPER + MASTER) =="
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  git_safe_pull "$name" "$(to_unix_path "$path")" "$DEFAULT_BRANCH" "$PRODUCTION_BRANCH"
  echo
done

echo "✅ Operação concluída"
