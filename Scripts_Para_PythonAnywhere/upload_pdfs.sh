#!/usr/bin/env bash

# =========================================================================
# UPLOAD PDFs - Local → PythonAnywhere
# =========================================================================
# Envia PDFs preparados para extração no PythonAnywhere
# De: C:/Applications_DSB/FinCtl/extratos/ArquivosTargetParaExtracao/
# Para: /home/davidbit/FinCtl/extratos/ArquivosTargetParaExtracao/
# =========================================================================

set -e

# Carregar configuração
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "========================================="
echo "   UPLOAD PDFs PARA PYTHONANYWHERE"
echo "========================================="
echo ""

# Diretórios
LOCAL_PDF_DIR="C:/Applications_DSB/FinCtl/extratos/ArquivosTargetParaExtracao"
REMOTE_PDF_DIR="/home/davidbit/FinCtl/extratos/ArquivosTargetParaExtracao"

# Verificar se pasta local existe
if [[ ! -d "$LOCAL_PDF_DIR" ]]; then
    echo "❌ ERRO: Diretório local não encontrado:"
    echo "   $LOCAL_PDF_DIR"
    exit 1
fi

# Contar PDFs
PDF_COUNT=$(find "$LOCAL_PDF_DIR" -maxdepth 1 -name "*.pdf" -type f 2>/dev/null | wc -l)

if [[ "$PDF_COUNT" -eq 0 ]]; then
    echo "⚠️  Nenhum PDF encontrado em:"
    echo "   $LOCAL_PDF_DIR"
    echo ""
    echo "ℹ️  Coloque os PDFs preparados nesta pasta antes de fazer upload"
    exit 0
fi

echo "📂 Diretório local: $LOCAL_PDF_DIR"
echo "📦 PDFs encontrados: $PDF_COUNT"
echo ""

# Listar PDFs
echo "📄 Arquivos a enviar:"
find "$LOCAL_PDF_DIR" -maxdepth 1 -name "*.pdf" -type f -exec basename {} \; | while read -r pdf; do
    echo "   • $pdf"
done
echo ""

# Confirmação
echo "🤔 Enviar esses $PDF_COUNT PDFs para PythonAnywhere? (s/n)"
read -r CONFIRMA

if [[ "$CONFIRMA" != "s" ]]; then
    echo "❌ Upload cancelado"
    exit 0
fi

# Criar diretório remoto se não existir
echo ""
echo "📁 Criando diretório no PythonAnywhere..."
ssh "$PA_USERNAME@$PA_HOSTNAME" "mkdir -p $REMOTE_PDF_DIR" || {
    echo "❌ ERRO ao criar diretório remoto"
    exit 1
}

# Upload dos PDFs
echo "📤 Enviando PDFs..."
echo ""

scp "$LOCAL_PDF_DIR"/*.pdf "$PA_USERNAME@$PA_HOSTNAME:$REMOTE_PDF_DIR/" || {
    echo ""
    echo "❌ ERRO durante upload"
    exit 1
}

echo ""
echo "========================================="
echo "   ✅ UPLOAD CONCLUÍDO!"
echo "========================================="
echo "📦 $PDF_COUNT PDFs enviados com sucesso"
echo "📂 Destino: $REMOTE_PDF_DIR"
echo ""
echo "📋 Próximos passos:"
echo "   1. Acessar PythonAnywhere"
echo "   2. Executar extração de despesas"
echo "   3. Verificar dados importados"
echo ""
