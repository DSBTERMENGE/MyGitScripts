#!/usr/bin/env bash

# =========================================================================
# PUSH - Scripts_Para_Git
# =========================================================================
# Script para enviar mudanças ao repositório remoto
# Verifica se remoto está mais adiantado antes de fazer push
# =========================================================================

set -e

echo "========================================="
echo "   GIT PUSH - Scripts_Para_Git"
echo "========================================="
echo ""

# Navegar para o repositório
cd "C:/Applications_DSB/Scripts_Para_Git"

# Atualizar informações do remoto
echo "🔄 Buscando informações do remoto..."
git fetch origin

# Verificar branch atual
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Branch atual: $CURRENT_BRANCH"
echo ""

# Verificar se remoto está mais adiantado
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

if [[ -z "$REMOTE" ]]; then
    echo "⚠️  Sem branch remoto configurado"
    echo "💡 Fazer push mesmo assim? (s/n)"
    read -r CONFIRMA
    if [[ "$CONFIRMA" != "s" ]]; then
        echo "❌ Push cancelado"
        exit 1
    fi
elif [[ "$LOCAL" = "$REMOTE" ]]; then
    echo "✅ Local e remoto estão sincronizados"
    echo "ℹ️  Nada a enviar"
    exit 0
elif [[ "$LOCAL" = "$BASE" ]]; then
    echo "❌ PERIGO! Remoto está mais adiantado que o local!"
    echo "⚠️  Você precisa fazer PULL primeiro para não perder trabalho"
    echo ""
    echo "Execute: ./pull.sh"
    exit 1
elif [[ "$REMOTE" = "$BASE" ]]; then
    echo "✅ Local está mais adiantado - seguro fazer push"
else
    echo "⚠️  Local e remoto divergiram!"
    echo "❌ Você precisa fazer PULL e resolver conflitos primeiro"
    echo ""
    echo "Execute: ./pull.sh"
    exit 1
fi

# Fazer o push
echo ""
echo "🚀 Enviando para origin/$CURRENT_BRANCH..."
git push origin "$CURRENT_BRANCH"

echo ""
echo "✅ Push realizado com sucesso!"
