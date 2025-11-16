#!/usr/bin/env bash

# =============================
# OPERAÇÕES GIT COMPARTILHADAS
# =============================
# Funções para operações Git reutilizáveis e seguras
#
# Para usar em outros scripts:
# source "$(dirname "${BASH_SOURCE[0]}")/../Comum/git_operations.sh"

# --- Garantir que sempre volta para developer ---
ensure_developer_branch() {
  local repo_path="$1"
  local repo_name="${2:-$(basename "$repo_path")}"
  
  if [[ ! -d "$repo_path/.git" ]]; then
    return 0  # Não é repo Git, ignorar
  fi
  
  local current_branch
  current_branch="$(run_git "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  
  if [[ "$current_branch" != "developer" ]]; then
    echo "🔄 [$repo_name] Voltando para branch developer..."
    if run_git "$repo_path" checkout developer 2>/dev/null; then
      echo "✅ [$repo_name] Branch developer ativada"
    else
      echo "⚠️  [$repo_name] Não foi possível voltar para developer (branch pode não existir)"
    fi
  fi
}

# --- Relatório de último commit ---
report_last_commit() {
  local repo_path="$1"
  run_git "$repo_path" log -1 --name-status --pretty=format:'%h %ad %an %s' --date=iso || true
}

# --- Commit seguro em um repositório ---
git_safe_commit() {
  local repo_name="$1"
  local repo_path="$2"
  local branch="$3"
  local message="$4"

  log "=== [$repo_name] ==="
  
  if [[ ! -d "$repo_path/.git" ]]; then
    log "[ERRO] Não é um repositório Git: $repo_path"
    return 1
  fi

  # Garantir branch correta
  local current_branch
  current_branch="$(run_git "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  if [[ "$current_branch" != "$branch" ]]; then
    log "Checkout para branch $branch"
    if ! run_git "$repo_path" checkout "$branch"; then
      log "[ERRO] Falha no checkout $branch"
      ensure_developer_branch "$repo_path" "$repo_name"
      return 1
    fi
  fi

  # Add e verificar alterações
  run_git "$repo_path" add -A
  local porcelain
  porcelain="$(run_git "$repo_path" status --porcelain || true)"

  if [[ -z "$porcelain" ]]; then
    log "Nenhuma alteração detectada. Nada a commitar."
    return 0
  fi

  # Commit
  local now_iso full_msg
  now_iso="$(date -u +"%Y-%m-%d %H:%M:%S UTC")"
  full_msg="[$now_iso] $message"
  if ! run_git "$repo_path" commit -m "$full_msg"; then
    log "[ERRO] Falha no commit"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 1
  fi

  log "Commit realizado. Último commit:"
  report_last_commit "$repo_path" | sed 's/^/  /'
  return 0
}

# --- Merge seguro developer → production ---
git_safe_merge() {
  local repo_name="$1"
  local repo_path="$2"
  local dev_branch="$3"
  local prod_branch="$4"

  echo "=== [$repo_name] ==="
  
  if [[ ! -d "$repo_path/.git" ]]; then
    echo "[ERRO] Não é repositório Git: $repo_path"
    return 1
  fi

  # Garantir que está em developer
  local current_branch
  current_branch="$(run_git "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  if [[ "$current_branch" != "$dev_branch" ]]; then
    echo "Checkout → $dev_branch"
    if ! run_git "$repo_path" checkout "$dev_branch"; then
      echo "[ERRO] Falha no checkout $dev_branch"
      ensure_developer_branch "$repo_path" "$repo_name"
      return 1
    fi
  fi

  # Verificar se branch de produção existe
  if ! run_git "$repo_path" rev-parse --verify "$prod_branch" >/dev/null 2>&1; then
    echo "[AVISO] Branch $prod_branch não existe; pulando merge."
    ensure_developer_branch "$repo_path" "$repo_name"
    return 0
  fi

  # Verificar diferenças
  local ahead_prod ahead_dev
  read -r ahead_prod ahead_dev < <(run_git "$repo_path" rev-list --left-right --count "$prod_branch...$dev_branch")
  ahead_prod="${ahead_prod:-0}"
  ahead_dev="${ahead_dev:-0}"
  echo "Diferenças: $prod_branch à frente=$ahead_prod | $dev_branch à frente=$ahead_dev"

  if (( ahead_dev > 0 )) && (( ahead_prod == 0 )); then
    echo "Atualizando $prod_branch por fast-forward a partir de $dev_branch…"
    if ! run_git "$repo_path" checkout "$prod_branch"; then
      echo "[ERRO] Falha no checkout $prod_branch"
      ensure_developer_branch "$repo_path" "$repo_name"
      return 1
    fi
    
    if run_git "$repo_path" merge --ff-only "$dev_branch"; then
      echo "Fast-forward aplicado em $prod_branch."
    else
      echo "[AVISO] Fast-forward não possível. Política impede merge com commit."
    fi
    
    # SEMPRE volta para developer
    ensure_developer_branch "$repo_path" "$repo_name"
  else
    echo "Sem fast-forward: ou $dev_branch não está à frente, ou $prod_branch tem commits próprios."
    ensure_developer_branch "$repo_path" "$repo_name"
  fi
  
  return 0
}

# --- Push seguro developer + production ---
git_safe_push() {
  local repo_name="$1"
  local repo_path="$2"
  local dev_branch="$3"
  local prod_branch="$4"

  echo "=== PUSH [$repo_name] - DEVELOPER + PRODUCTION ==="
  
  if [[ ! -d "$repo_path/.git" ]]; then
    echo "❌ [$repo_name] Não é repositório Git: $repo_path"
    return 1
  fi
  
  # 1. Push da branch developer
  echo "📤 [$repo_name] Fazendo push da branch $dev_branch..."
  if ! run_git "$repo_path" push origin "$dev_branch" 2>&1; then
    echo "❌ [$repo_name] Push da $dev_branch falhou"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 1
  fi
  echo "✅ [$repo_name] Push da $dev_branch realizado com sucesso"
  
  # 2. Verificar se branch production existe localmente
  if ! run_git "$repo_path" rev-parse --verify "$prod_branch" >/dev/null 2>&1; then
    echo "⚠️  [$repo_name] Branch $prod_branch não existe localmente - pulando push"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 0
  fi
  
  # 3. Switch para production
  echo "🔄 [$repo_name] Mudando para branch $prod_branch..."
  if ! run_git "$repo_path" checkout "$prod_branch" 2>&1; then
    echo "❌ [$repo_name] Falha ao mudar para $prod_branch"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 1
  fi
  
  # 4. Verificar se production tem commits para enviar
  local ahead_prod=0
  if run_git "$repo_path" rev-parse --verify "origin/$prod_branch" >/dev/null 2>&1; then
    ahead_prod=$(run_git "$repo_path" rev-list --count "$prod_branch" "^origin/$prod_branch" 2>/dev/null || echo "0")
  else
    ahead_prod=$(run_git "$repo_path" rev-list --count "$prod_branch" 2>/dev/null || echo "0")
    echo "⚠️  [$repo_name] Branch $prod_branch remota não existe - será criada"
  fi
  
  if [[ "$ahead_prod" -eq 0 ]]; then
    echo "ℹ️  [$repo_name] $prod_branch já está sincronizada (nenhum commit novo)"
  else
    echo "📤 [$repo_name] Fazendo push da branch $prod_branch ($ahead_prod commits)..."
    if ! run_git "$repo_path" push origin "$prod_branch" 2>&1; then
      echo "❌ [$repo_name] Push da $prod_branch falhou"
      ensure_developer_branch "$repo_path" "$repo_name"
      return 1
    fi
    echo "✅ [$repo_name] Push da $prod_branch realizado com sucesso"
  fi
  
  # 5. SEMPRE volta para developer
  ensure_developer_branch "$repo_path" "$repo_name"
  return 0
}

# --- Pull seguro ---
git_safe_pull() {
  local repo_name="$1"
  local repo_path="$2"
  local branch="$3"

  echo "=== PULL [$repo_name] ==="
  
  if [[ ! -d "$repo_path/.git" ]]; then
    echo "❌ [$repo_name] Não é repositório Git: $repo_path"
    return 1
  fi

  # Garantir branch correta
  local current_branch
  current_branch="$(run_git "$repo_path" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
  if [[ "$current_branch" != "$branch" ]]; then
    echo "Checkout → $branch"
    if ! run_git "$repo_path" checkout "$branch"; then
      echo "❌ [$repo_name] Falha no checkout $branch"
      ensure_developer_branch "$repo_path" "$repo_name"
      return 1
    fi
  fi

  # Verificar working directory limpo
  local status_porcelain
  status_porcelain="$(run_git "$repo_path" status --porcelain 2>&1 || true)"
  if [[ -n "$status_porcelain" ]]; then
    echo "❌ [$repo_name] Working directory não está limpo"
    echo "    Faça commit ou stash das alterações antes do pull"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 1
  fi

  # Fetch
  echo "🔄 [$repo_name] Atualizando referências remotas (fetch)..."
  if ! run_git "$repo_path" fetch --all --prune 2>&1; then
    echo "❌ [$repo_name] Falha no fetch"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 1
  fi

  # Pull
  echo "📥 [$repo_name] Fazendo pull..."
  if ! run_git "$repo_path" pull origin "$branch" 2>&1; then
    echo "❌ [$repo_name] Pull falhou"
    ensure_developer_branch "$repo_path" "$repo_name"
    return 1
  fi

  echo "✅ [$repo_name] Pull realizado com sucesso"
  ensure_developer_branch "$repo_path" "$repo_name"
  return 0
}
