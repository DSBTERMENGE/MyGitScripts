#!/usr/bin/env bash

# =========================================================================
# UPLOAD SCRIPT - Local → PythonAnywhere
# =========================================================================
# Envia atualizar_producao.sh via SCP para PythonAnywhere
# =========================================================================

set -e

# Carregar configuração
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "========================================="
echo "   UPLOAD PARA PYTHONANYWHERE"
echo "========================================="
echo ""

# Criar diretório scripts se não existir
echo "📁 Criando diretório no PythonAnywhere..."
ssh "$PA_USERNAME@$PA_HOSTNAME" "mkdir -p $PA_SCRIPTS_DIR"
echo ""

# Upload do script
echo "📤 Enviando atualizar_producao.sh..."
scp "$SCRIPT_DIR/atualizar_producao.sh" \
    "$PA_USERNAME@$PA_HOSTNAME:$PA_SCRIPTS_DIR/atualizar_producao.sh"

echo ""
echo "✅ Upload concluído!"
echo ""
echo "========================================="
echo "📋 PRÓXIMOS PASSOS:"
echo "========================================="
echo ""
echo "1. Abrir Bash Console no PythonAnywhere"
echo "2. Executar:"
echo "   bash ~/scripts/atualizar_producao.sh"
echo ""
echo "Isso atualizará os 3 repositórios:"
echo "  • framework_dsb/backend"
echo "  • framework_dsb/frontend"
echo "  • FinCtl"
echo ""
