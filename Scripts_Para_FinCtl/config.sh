#!/usr/bin/env bash

# =============================
# CONFIGURAÇÃO ESPECÍFICA - FinCtl
# =============================
# Este arquivo contém configurações específicas do FinCtl
# Para usar em outros scripts, adicione no início:
# source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# --- Carregar Configurações Base Compartilhadas ---
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/../Comum/config_base.sh"

# --- Nome do Aplicativo ---
APP_NAME="FinCtl"

# --- Repositórios ---
REPOS=(
  "FinCtl|C:/Applications_DSB/FinCtl"
  "backend|C:/Applications_DSB/framework_dsb/backend"
  "frontend|C:/Applications_DSB/framework_dsb/frontend"
)

# --- Configuração do Banco de Dados ---
DB_PATH="C:/Applications_DSB/FinCtl/data"
DB_FILES="financas.db"