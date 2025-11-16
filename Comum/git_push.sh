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

# =============================
# Verificações de segurança por repositório
# =============================
check_repo_safety() {
  local name="$1"
  local raw_path="$2"
  local branch="$3"
  
  local path
  path="$(to_unix_path "$raw_path")"

  echo "=== VERIFICANDO [$name] ==="
  
  # 1. Verificar se é repositório Git
  if [[ ! -d "$path/.git" ]]; then
    echo "❌ [$name] Não é um repositório Git: $path"
    return 1
  fi

  # 2. Verificar branch atual
  local current_branch
  current_branch="$(run_git "$path" rev-parse --abbrev-ref HEAD 2>&1 || echo '?')"
  if [[ "$current_branch" != "$branch" ]]; then
    echo "❌ [$name] Branch atual ($current_branch) ≠ esperada ($branch)"
    return 1
  fi

  # 3. Verificar working directory limpo
  local status_porcelain
  status_porcelain="$(run_git "$path" status --porcelain 2>&1 || true)"
  if [[ -n "$status_porcelain" ]]; then
    echo "❌ [$name] Working directory não está limpo:"
    echo "$status_porcelain" | sed 's/^/    /'
    echo "    Faça commit ou stash das alterações antes do push"
    return 1
  fi

  # 4. Fetch para atualizar referências remotas
  echo "🔄 [$name] Atualizando referências remotas (fetch)..."
  if ! run_git "$path" fetch --all --prune 2>&1; then
    echo "❌ [$name] Falha no fetch. Verifique conectividade"
    return 1
  fi

  # 5. Verificar se branch remota existe
  local remote_branch="origin/$branch"
  if ! run_git "$path" rev-parse --verify "$remote_branch" >/dev/null 2>&1; then
    echo "⚠️  [$name] Branch remota $remote_branch não existe"
    echo "    Será criada no primeiro push"
    return 0  # Permite push para nova branch
  fi

  # 6. Verificar relação local vs remoto
  local ahead behind
  read -r ahead behind < <(run_git "$path" rev-list --left-right --count "HEAD...$remote_branch" 2>&1)
  ahead="${ahead:-0}"
  behind="${behind:-0}"

  echo "📊 [$name] Status: local à frente=$ahead | local atrás=$behind"

  # 7. IMPEDIMENTO CRÍTICO: local atrás do remoto
  if (( behind > 0 )); then
    echo "❌ [$name] Local está $behind commits ATRÁS do remoto!"
    echo "    O push sobrescreveria conteúdo mais novo no servidor"
    echo "    Execute git pull primeiro para integrar mudanças remotas"
    return 1
  fi

  # 8. Verificar se há commits para enviar
  if (( ahead == 0 )); then
    echo "ℹ️  [$name] Nenhum commit novo para enviar (já sincronizado)"
    return 2  # Código especial: não precisa push mas não é erro
  fi

  # 9. Mostrar o que será enviado
  echo "📤 [$name] Commits que serão enviados ($ahead):"
  run_git "$path" log --oneline "$remote_branch..HEAD" | sed 's/^/    /' || true

  # 10. Dry-run para verificar se push seria bem-sucedido
  echo "🧪 [$name] Testando push (dry-run)..."
  if ! run_git "$path" push --dry-run origin "$branch" 2>&1; then
    echo "❌ [$name] Dry-run falhou. Push seria rejeitado"
    return 1
  fi

  echo "✅ [$name] Seguro para push"
  return 0
}

# =============================
# Fluxo principal
# =============================
echo "========================================="
echo "   PUSH SEGURO"
echo "   Aplicativo: $APP_NAME"
echo "   Branch: $DEFAULT_BRANCH"
echo "   Máxima proteção contra perda de dados"
echo "========================================="
echo

# Array para controlar quais repos são seguros
declare -a SAFE_REPOS=()
declare -a SKIP_REPOS=()
declare -a FAILED_REPOS=()

echo "== VERIFICAÇÕES DE SEGURANÇA =="
for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  
  check_repo_safety "$name" "$path" "$DEFAULT_BRANCH"
  result=$?
  if [[ $result -eq 0 ]]; then
    SAFE_REPOS+=("$entry")
  elif [[ $result -eq 2 ]]; then
    SKIP_REPOS+=("$entry")
  else
    FAILED_REPOS+=("$entry")
  fi
  echo
done

# Relatório de verificações
echo "========================================="
echo "   RELATÓRIO DE VERIFICAÇÕES"
echo "========================================="
echo "✅ Seguros para push: ${#SAFE_REPOS[@]}"
echo "ℹ️  Não precisam push: ${#SKIP_REPOS[@]}"
echo "❌ Com impedimentos: ${#FAILED_REPOS[@]}"
echo

if [[ ${#FAILED_REPOS[@]} -gt 0 ]]; then
  echo "❌ REPOSITÓRIOS COM IMPEDIMENTOS:"
  for entry in "${FAILED_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    echo "   - $name"
  done
  echo
fi

if [[ ${#SKIP_REPOS[@]} -gt 0 ]]; then
  echo "ℹ️  REPOSITÓRIOS QUE NÃO PRECISAM PUSH:"
  for entry in "${SKIP_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    echo "   - $name (já sincronizado)"
  done
  echo
fi

# Se não há repos seguros, encerrar
if [[ ${#SAFE_REPOS[@]} -eq 0 ]]; then
  echo "⚠️  Nenhum repositório seguro para push. Operação cancelada."
  echo "Verifique os impedimentos acima e resolva antes de tentar novamente."
  exit 0
fi

# Confirmação final
echo "✅ REPOSITÓRIOS SEGUROS PARA PUSH:"
for entry in "${SAFE_REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  echo "   - $name"
done
echo

read -rp "🤔 Confirma o push dos repositórios seguros? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
  echo "❌ Push cancelado pelo usuário"
  exit 0
fi

# Executar push nos repositórios seguros
echo
echo "== EXECUTANDO PUSH (DEVELOPER + MASTER) =="
SUCCESS_COUNT=0
for entry in "${SAFE_REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  if git_safe_push "$name" "$(to_unix_path "$path")" "$DEFAULT_BRANCH" "$PRODUCTION_BRANCH"; then
    ((SUCCESS_COUNT++))
  fi
  echo
done

# Relatório final
echo
echo "========================================="
echo "   RELATÓRIO FINAL"
echo "========================================="
echo "✅ Push completo (developer + master): $SUCCESS_COUNT/${#SAFE_REPOS[@]} repositórios"
echo "🎯 Todos os repositórios voltaram para branch developer"
echo
echo "Operação concluída em $(ts)"
