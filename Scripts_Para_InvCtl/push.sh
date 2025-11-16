#!/usr/bin/env bash

# =============================
# WRAPPER - GIT PUSH (InvCtl)
# =============================
# Este wrapper carrega as configurações específicas do InvCtl
# e chama o script genérico em Comum/

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Carregar configurações
source "$SCRIPT_DIR/../Comum/config_base.sh"
source "$SCRIPT_DIR/../Comum/funcoes_auxiliares.sh"
source "$SCRIPT_DIR/../Comum/git_operations.sh"
source "$SCRIPT_DIR/config.sh"

# Chamar script genérico
exec bash "$SCRIPT_DIR/../Comum/git_push.sh"
