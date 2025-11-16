#!/usr/bin/env bash

# =============================
# SCRIPT GENÉRICO - GIT PULL
# =============================
# Este script é GENÉRICO e pode ser usado por qualquer aplicativo
# Estratégia: Verificar primeiro, backup só se necessário

# Validar que configurações necessárias foram carregadas
if [[ -z "${APP_NAME:-}" ]]; then
  echo "❌ ERRO: Configurações não foram carregadas!"
  echo "💡 Use o wrapper específico do aplicativo (ex: pull.sh)"
  exit 1
fi

# =============================
# VERIFICAÇÃO DE SEGURANÇA PRÉ-BACKUP
# =============================
check_pull_conditions() {
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
    echo "    Faça commit ou stash das alterações antes do pull"
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
    echo "ℹ️  [$name] Branch remota $remote_branch não existe"
    return 2  # SKIP - não há remoto para puxar
  fi

  # 6. Verificar relação local vs remoto
  local ahead behind
  read -r ahead behind < <(run_git "$path" rev-list --left-right --count "HEAD...$remote_branch" 2>&1)
  ahead="${ahead:-0}"
  behind="${behind:-0}"

  echo "📊 [$name] Status: local à frente=$ahead | remoto à frente=$behind"

  # 7. Verificar se há algo para puxar
  if (( behind == 0 )); then
    echo "ℹ️  [$name] Repositório já atualizado (nada para puxar)"
    return 2  # SKIP - já atualizado
  fi

  # 8. Verificar tipo de pull necessário
  if (( ahead == 0 && behind > 0 )); then
    echo "✅ [$name] Fast-forward possível ($behind commits)"
    echo "📥 [$name] Commits que serão puxados:"
    run_git "$path" log --oneline "HEAD..$remote_branch" | sed 's/^/    /' || true
    return 0  # SAFE_FF
  fi

  if (( ahead > 0 && behind > 0 )); then
    echo "⚠️  [$name] Divergência detectada: local +$ahead, remoto +$behind"
    echo "    Será necessário merge - verificando conflitos potenciais..."
    
    # Verificar conflitos potenciais
    local merge_base
    merge_base="$(run_git "$path" merge-base HEAD "$remote_branch" 2>/dev/null || echo '')"
    
    if [[ -n "$merge_base" ]]; then
      local local_files remote_files
      local_files="$(run_git "$path" diff --name-only "$merge_base" HEAD 2>/dev/null || true)"
      remote_files="$(run_git "$path" diff --name-only "$merge_base" "$remote_branch" 2>/dev/null || true)"
      
      if [[ -n "$local_files" && -n "$remote_files" ]]; then
        local conflicts
        conflicts="$(comm -12 <(echo "$local_files" | sort) <(echo "$remote_files" | sort) || true)"
        if [[ -n "$conflicts" ]]; then
          echo "⚠️  [$name] CONFLITOS POTENCIAIS detectados nos arquivos:"
          echo "$conflicts" | sed 's/^/    /'
          echo "    Merge pode necessitar resolução manual"
        fi
      fi
    fi
    
    echo "📥 [$name] Commits remotos que serão mesclados:"
    run_git "$path" log --oneline "HEAD..$remote_branch" | sed 's/^/    /' || true
    return 3  # SAFE_MERGE
  fi

  echo "❌ [$name] Status inesperado (ahead=$ahead, behind=$behind)"
  return 1
}

# =============================
# EXECUTAR PULL SEGURO
# =============================
pull_repo() {
  local name="$1"
  local raw_path="$2"
  local branch="$3"
  local strategy="$4"
  
  local path
  path="$(to_unix_path "$raw_path")"

  echo "=== PULL [$name] - Estratégia: $strategy ==="
  
  case "$strategy" in
    "fast-forward")
      if ! run_git "$path" pull --ff-only origin "$branch" 2>&1; then
        echo "❌ [$name] Fast-forward falhou"
        return 1
      fi
      ;;
    "merge")
      if ! run_git "$path" pull --no-ff origin "$branch" 2>&1; then
        echo "❌ [$name] Merge falhou"
        return 1
      fi
      ;;
    *)
      echo "❌ [$name] Estratégia desconhecida: $strategy"
      return 1
      ;;
  esac

  echo "✅ [$name] Pull realizado com sucesso"
  
  # Mostrar último commit após pull
  echo "📥 [$name] Estado após pull:"
  run_git "$path" log -1 --oneline | sed 's/^/    /'
  
  return 0
}

# =============================
# FLUXO PRINCIPAL
# =============================
echo "========================================="
echo "   PULL SEGURO"
echo "   Aplicativo: $APP_NAME"
echo "   Branch: $DEFAULT_BRANCH"
echo "   Estratégia: Verificar → Backup → Pull"
echo "========================================="
echo

# FASE 1: VERIFICAÇÕES PRÉ-BACKUP (RÁPIDAS)
echo "== FASE 1: VERIFICAÇÕES INICIAIS (SEM BACKUP) =="
declare -a SAFE_FF_REPOS=()
declare -a SAFE_MERGE_REPOS=()
declare -a SKIP_REPOS=()
declare -a FAILED_REPOS=()

for entry in "${REPOS[@]}"; do
  IFS='|' read -r name path <<<"$entry"
  
  check_pull_conditions "$name" "$path" "$DEFAULT_BRANCH"
  result=$?
  
  case $result in
    0) SAFE_FF_REPOS+=("$entry") ;;
    1) FAILED_REPOS+=("$entry") ;;
    2) SKIP_REPOS+=("$entry") ;;
    3) SAFE_MERGE_REPOS+=("$entry") ;;
  esac
  echo
done

# Relatório da Fase 1
echo "========================================="
echo "   RELATÓRIO DA FASE 1"
echo "========================================="
echo "✅ Prontos para fast-forward: ${#SAFE_FF_REPOS[@]}"
echo "🔀 Precisam de merge: ${#SAFE_MERGE_REPOS[@]}"
echo "ℹ️  Já atualizados/sem necessidade: ${#SKIP_REPOS[@]}"
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
  echo "ℹ️  REPOSITÓRIOS QUE NÃO PRECISAM PULL:"
  for entry in "${SKIP_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    echo "   - $name (já atualizado)"
  done
  echo
fi

# Verificar se há algo para fazer
total_repos_to_pull=$((${#SAFE_FF_REPOS[@]} + ${#SAFE_MERGE_REPOS[@]}))
if [[ $total_repos_to_pull -eq 0 ]]; then
  echo "✅ Nenhum repositório precisa de pull. Operação concluída."
  echo "Operação concluída em $(ts)"
  exit 0
fi

# FASE 2: BACKUP + PULL (SÓ SE NECESSÁRIO)
echo "== FASE 2: BACKUP DE SEGURANÇA =="
echo "🔍 Repositórios necessitam pull - iniciando backup de segurança..."

# Backup do aplicativo específico
if ! do_backup_app "$APP_NAME" "C:/Applications_DSB/${APP_NAME}"; then
  echo "❌ Falha no backup do aplicativo. Abortando por segurança."
  exit 1
fi
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/${APP_NAME}" "${APP_NAME}"

# Backup do framework_dsb (compartilhado)
if ! do_backup_framework; then
  echo "❌ Falha no backup do framework. Abortando por segurança."
  exit 1
fi
DeletaBkpMaisAntigo "${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/framework_dsb" "framework_dsb"

echo "✅ Backup de segurança concluído"
echo

# Confirmação final
echo "== CONFIRMAÇÃO FINAL =="
if [[ ${#SAFE_FF_REPOS[@]} -gt 0 ]]; then
  echo "✅ FAST-FORWARD (${#SAFE_FF_REPOS[@]} repositórios):"
  for entry in "${SAFE_FF_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    echo "   - $name"
  done
fi

if [[ ${#SAFE_MERGE_REPOS[@]} -gt 0 ]]; then
  echo "🔀 MERGE (${#SAFE_MERGE_REPOS[@]} repositórios):"
  for entry in "${SAFE_MERGE_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    echo "   - $name"
  done
fi

echo
read -rp "🤔 Confirma o pull dos repositórios listados? (s/N): " confirm
if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
  echo "❌ Pull cancelado pelo usuário"
  exit 0
fi

# FASE 3: EXECUÇÃO DOS PULLS
echo
echo "== FASE 3: EXECUTANDO PULLS =="
SUCCESS_COUNT=0

# Executar fast-forwards primeiro (mais seguro)
if [[ ${#SAFE_FF_REPOS[@]} -gt 0 ]]; then
  echo "--- Executando Fast-Forwards ---"
  for entry in "${SAFE_FF_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    if pull_repo "$name" "$path" "$DEFAULT_BRANCH" "fast-forward"; then
      ((SUCCESS_COUNT++))
    fi
  done
fi

# Executar merges depois
if [[ ${#SAFE_MERGE_REPOS[@]} -gt 0 ]]; then
  echo "--- Executando Merges ---"
  for entry in "${SAFE_MERGE_REPOS[@]}"; do
    IFS='|' read -r name path <<<"$entry"
    if pull_repo "$name" "$path" "$DEFAULT_BRANCH" "merge"; then
      ((SUCCESS_COUNT++))
    fi
  done
fi

# Relatório final
echo
echo "========================================="
echo "   RELATÓRIO FINAL"
echo "========================================="
echo "✅ Pull bem-sucedido: $SUCCESS_COUNT/$total_repos_to_pull repositórios"
echo
echo "Operação concluída em $(ts)"
