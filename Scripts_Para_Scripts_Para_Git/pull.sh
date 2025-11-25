#!/usr/bin/env bash

# =========================================================================
# PULL - Scripts_Para_Git
# =========================================================================
# Script para puxar mudanças do repositório remoto
# Verifica se local está mais adiantado antes de fazer pull
# =========================================================================

set -e

echo "========================================="
echo "   GIT PULL - Scripts_Para_Git"
echo "========================================="
echo ""

# Navegar para o repositório
cd "C:/Applications_DSB/Scripts_Para_Git"

# Verificar se há mudanças não commitadas
if [[ -n "$(git status --porcelain)" ]]; then
    echo "❌ PERIGO! Há mudanças não commitadas no working tree!"
    echo "⚠️  Faça commit ou stash antes de fazer pull"
    echo ""
    git status --short
    exit 1
fi

# Atualizar informações do remoto
echo "🔄 Buscando informações do remoto..."
git fetch origin

# Verificar branch atual
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Branch atual: $CURRENT_BRANCH"
echo ""

# Verificar se local está mais adiantado
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null || echo "")
BASE=$(git merge-base @ @{u} 2>/dev/null || echo "")

if [[ -z "$REMOTE" ]]; then
    echo "⚠️  Sem branch remoto configurado"
    exit 1
elif [[ "$LOCAL" = "$REMOTE" ]]; then
    echo "✅ Local e remoto estão sincronizados"
    echo "ℹ️  Nada a puxar"
    exit 0
elif [[ "$REMOTE" = "$BASE" ]]; then
    echo "❌ PERIGO! Local está mais adiantado que o remoto!"
    echo "⚠️  Você tem commits locais que ainda não foram enviados"
    echo ""
    echo "Execute: ./push.sh para enviar suas mudanças primeiro"
    exit 1
elif [[ "$LOCAL" = "$BASE" ]]; then
    echo "✅ Remoto está mais adiantado - seguro fazer pull"
else
    echo "⚠️  Local e remoto divergiram!"
    echo "❌ Há commits diferentes em ambos os lados"
    echo "💡 Fazer pull com merge? (s/n)"
    read -r CONFIRMA
    if [[ "$CONFIRMA" != "s" ]]; then
        echo "❌ Pull cancelado"
        exit 1
    fi
fi

# Fazer o pull
echo ""
echo "⬇️  Puxando de origin/$CURRENT_BRANCH..."
git pull origin "$CURRENT_BRANCH"

echo ""
echo "✅ Pull realizado com sucesso!"
