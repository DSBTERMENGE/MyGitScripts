#!/usr/bin/env bash

# =============================
# FUNÇÕES AUXILIARES COMPARTILHADAS
# =============================
# Funções compartilhadas para backup e operações auxiliares
#
# Para usar em outros scripts:
# source "$(dirname "${BASH_SOURCE[0]}")/../Comum/funcoes_auxiliares.sh"

# --- Funções Básicas ---
ts() { 
  date +"%Y-%m-%d %H:%M:%S" 
}

to_unix_path() {
  local p="$1"
  printf '%s' "$p"
}

run_git() {
  local repo_path="$1"; shift
  
  if [[ ! -d "$repo_path" ]]; then
    echo "❌ [ERROR] Diretório não existe: $repo_path" >&2
    return 1
  fi
  
  ( cd "$repo_path" && git "$@" 2>&1 )
}

log() { 
  echo "[$(ts)] $*" | tee -a "$LOG_FILE" 
}

# --- Função de Backup do Aplicativo Específico ---
do_backup_app() {
  local app_name="$1"
  local app_path="$2"
  
  # Validações
  if [[ -z "$app_name" ]]; then
    echo "❌ [BACKUP APP] Nome do aplicativo não fornecido"
    return 1
  fi
  
  if [[ ! -d "$app_path" ]]; then
    echo "❌ [BACKUP APP] Diretório não existe: $app_path"
    return 1
  fi
  
  # Definir destino: {GoogleDrive}/{machine}/{AppName}/
  local backup_dest="${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/${app_name}"
  
  # Validar que pasta de backup existe (infraestrutura)
  if [[ ! -d "$backup_dest" ]]; then
    echo "❌ [BACKUP APP] Pasta de backup não existe: $backup_dest"
    echo "💡 Crie manualmente a infraestrutura de pastas antes"
    return 1
  fi
  
  # Criar novo backup com timestamp
  local timestamp="$(date +"%Y%m%d_%H%M%S")"
  local new_backup="${backup_dest}/${app_name}_${timestamp}"
  
  echo "📦 Criando backup de $app_name: ${app_name}_${timestamp}"
  
  # Copiar pasta do aplicativo
  if ! cp -a "$app_path"/. "$new_backup"/; then
    echo "❌ [BACKUP APP] Falha ao copiar: $app_path"
    return 1
  fi
  
  echo "✅ Backup de $app_name criado com sucesso"
  return 0
}

# --- Função de Backup do Framework (compartilhado por todos os apps) ---
do_backup_framework() {
  local framework_path="C:/Applications_DSB/framework_dsb"
  
  # Validação
  if [[ ! -d "$framework_path" ]]; then
    echo "❌ [BACKUP FRAMEWORK] Diretório não existe: $framework_path"
    return 1
  fi
  
  # Definir destino: {GoogleDrive}/{machine}/framework_dsb/
  local backup_dest="${GOOGLE_DRIVE_BASE}/${BACKUP_SUBDIR}/framework_dsb"
  
  # Validar que pasta de backup existe (infraestrutura)
  if [[ ! -d "$backup_dest" ]]; then
    echo "❌ [BACKUP FRAMEWORK] Pasta de backup não existe: $backup_dest"
    echo "💡 Crie manualmente a infraestrutura de pastas antes"
    return 1
  fi
  
  # Criar novo backup com timestamp
  local timestamp="$(date +"%Y%m%d_%H%M%S")"
  local new_backup="${backup_dest}/framework_dsb_${timestamp}"
  
  echo "📦 Criando backup de framework_dsb: framework_dsb_${timestamp}"
  
  # Copiar pasta framework_dsb completa (com backend e frontend)
  if ! cp -a "$framework_path"/. "$new_backup"/; then
    echo "❌ [BACKUP FRAMEWORK] Falha ao copiar: $framework_path"
    return 1
  fi
  
  echo "✅ Backup de framework_dsb criado com sucesso"
  return 0
}

# --- Função para Deletar Backup Mais Antigo ---
DeletaBkpMaisAntigo() {
  local backup_dest="$1"
  local backup_base_name="$2"
  
  echo "🧹 Verificando necessidade de limpeza..."
  
  # Listar backups ordenados por NOME (timestamp) - mais antigo primeiro
  mapfile -t backups < <(ls -1d "${backup_dest}/${backup_base_name}_"* 2>/dev/null | sort || true)
  
  local total_backups=${#backups[@]}
  echo "📊 Total de backups encontrados: $total_backups"
  
  # Se tiver mais de 3, remover o mais antigo (primeiro da lista ordenada por nome/timestamp)
  if (( total_backups > 3 )); then
    echo "🗑️  Limite excedido! Removendo backup mais antigo:"
    echo "   Deletando: $(basename "${backups[0]}")"
    rm -rf "${backups[0]}"
    echo "✅ Limpeza concluída. Restam 3 backups."
  else
    echo "✅ Limite OK. Mantendo $total_backups backup(s)."
  fi
  
  return 0
}

# --- Função para Listar Backups ---
list_backups() {
  local backup_dest="$1"
  local backup_base_name="$2"
  
  echo "📋 Backups disponíveis:"
  ls -1dt "${backup_dest}/${backup_base_name}_"* 2>/dev/null | while read -r backup_dir; do
    local backup_name="$(basename "$backup_dir")"
    local backup_date="${backup_name##*_}"
    local formatted_date="${backup_date:0:4}/${backup_date:4:2}/${backup_date:6:2} ${backup_date:9:2}:${backup_date:11:2}:${backup_date:13:2}"
    echo "  📁 $backup_name → $formatted_date"
  done || echo "  Nenhum backup encontrado"
}
