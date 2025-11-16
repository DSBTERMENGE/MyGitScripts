#!/usr/bin/env bash

# =============================
# CONFIGURAÇÃO ESPECÍFICA - InvCtl
# =============================
# Este arquivo contém configurações específicas do InvCtl
# Para usar em outros scripts, adicione no início:
# source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

# --- Carregar Configurações Base Compartilhadas ---
SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"
source "$SCRIPT_DIR/../Comum/config_base.sh"

# --- Nome do Aplicativo ---
APP_NAME="InvCtl"

# --- Repositórios ---
REPOS=(
  "InvCtl|C:/Applications_DSB/InvCtl"
  "backend|C:/Applications_DSB/framework_dsb/backend"
  "frontend|C:/Applications_DSB/framework_dsb/frontend"
)

# --- Configuração do Banco de Dados ---
DB_PATH="C:/Applications_DSB/InvCtl/data"
DB_FILES="inventory.db"
