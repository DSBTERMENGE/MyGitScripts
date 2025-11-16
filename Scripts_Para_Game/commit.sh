#!/usr/bin/env bash
set -euo pipefail

# =============================
# WRAPPER - GIT COMMIT (Game)
# =============================
# Este wrapper carrega as configurações específicas do Game
# e chama o script genérico em Comum/

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Carregar configurações
source "$SCRIPT_DIR/config.sh"
source "$SCRIPT_DIR/../Comum/funcoes_auxiliares.sh"
source "$SCRIPT_DIR/../Comum/git_operations.sh"

# Chamar script genérico
source "$SCRIPT_DIR/../Comum/git_commit.sh"
