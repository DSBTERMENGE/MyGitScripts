#!/usr/bin/env bash

# =========================================================================
# COMMIT - Scripts_Para_Git
# =========================================================================
# Script para commitar mudanças no repositório Scripts_Para_Git
# Usa comandos git diretos (não usa wrapper pattern para evitar recursão)
# =========================================================================

set -e

echo "========================================="
echo "   GIT COMMIT - Scripts_Para_Git"
echo "========================================="
echo ""

# Navegar para o repositório
cd "C:/Applications_DSB/Scripts_Para_Git"

# Verificar se há mudanças
if [[ -z "$(git status --porcelain)" ]]; then
    echo "✅ Nada a commitar - working tree limpo"
    exit 0
fi

# Mostrar mudanças
echo "📋 Mudanças detectadas:"
echo ""
git status --short
echo ""

# Pedir descrição do commit
echo "💬 Digite a descrição do commit:"
read -r COMMIT_MSG

# Validar mensagem não vazia
if [[ -z "$COMMIT_MSG" ]]; then
    echo "❌ Mensagem não pode ser vazia!"
    exit 1
fi

# Fazer o commit
git add -A
git commit -m "$COMMIT_MSG"

echo ""
echo "✅ Commit realizado com sucesso!"
echo "📝 Mensagem: $COMMIT_MSG"
