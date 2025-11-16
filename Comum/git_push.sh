#!/usr/bin/env bash

# =============================
# SCRIPT GENÉRICO - GIT PUSH
# =============================
# Este script é GENÉRICO e pode ser usado por qualquer aplicativo
# Máxima segurança: verifica tudo antes de enviar
# Push de developer + master, volta sempre para developer

# Validar que configurações necessárias foram carregadas
if [[ -z "${APP_NAME:-}" ]]; then
  echo "❌ ERRO: Configurações não foram carregadas!"
  echo "💡 Use o wrapper específico do aplicativo (ex: push.sh)"
  exit 1
fi

echo "========================================="
echo "   PUSH DEVELOPER + MASTER"
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
  echo "❌ Há repositórios com estrutura inválida. Corrija antes de fazer push."
  exit 1
fi

echo "✅ Estrutura validada"
echo

# Executar push nos repositórios
echo "== EXECUTANDO PUSH (DEVELOPER + MASTER) =="
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  git_safe_push "$name" "$(to_unix_path "$path")" "$DEFAULT_BRANCH" "$PRODUCTION_BRANCH"
  echo
done

echo "✅ Operação concluída"
