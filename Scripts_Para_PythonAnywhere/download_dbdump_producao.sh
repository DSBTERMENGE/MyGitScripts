#!/usr/bin/env bash

# =========================================================================
# DOWNLOAD DB DUMP PRODUÇÃO - PythonAnywhere → Local
# =========================================================================
# Baixa dump PostgreSQL do PythonAnywhere e restaura no banco local
# Banco local ficará idêntico ao de produção
# =========================================================================

set -e

# Carregar configuração
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

echo "========================================="
echo "   DOWNLOAD DB DUMP - PRODUÇÃO → LOCAL"
echo "========================================="
echo ""

# Configurações PostgreSQL
PG_HOST_PROD="DavidBit-4926.postgres.pythonanywhere-services.com"
PG_PORT_PROD="14926"
PG_DATABASE="financas"
PG_USER_PROD="super"

# Configurações locais
LOCAL_DUMP_DIR="C:/Applications_DSB/FinCtl/data/dumps"
LOCAL_DUMP_FILE="$LOCAL_DUMP_DIR/financas_producao.sql"
REMOTE_TEMP_DUMP="/tmp/financas_dump_$(date +%Y%m%d_%H%M%S).sql"

# PostgreSQL local (assumindo instalação padrão)
PG_LOCAL_USER="postgres"
PG_LOCAL_HOST="localhost"
PG_LOCAL_PORT="5432"

echo "⚠️  ATENÇÃO: Este script irá:"
echo "   1. Baixar dump do banco de produção"
echo "   2. APAGAR completamente o banco local 'financas'"
echo "   3. Recriar e restaurar com dados de produção"
echo ""
echo "🤔 Tem certeza que deseja continuar? (s/n)"
read -r CONFIRMA

if [[ "$CONFIRMA" != "s" ]]; then
    echo "❌ Operação cancelada"
    exit 0
fi

echo ""
echo "========================================="
echo "FASE 1: Gerar Dump no PythonAnywhere"
echo "========================================="

# Gerar dump no PythonAnywhere
echo "🔄 Conectando ao PythonAnywhere e gerando dump..."
ssh "$PA_USERNAME@$PA_HOSTNAME" << ENDSSH
export PGPASSWORD='$PG_USER_PROD'
pg_dump -h $PG_HOST_PROD -p $PG_PORT_PROD -U $PG_USER_PROD -d $PG_DATABASE -F p -f $REMOTE_TEMP_DUMP
echo "✅ Dump gerado: $REMOTE_TEMP_DUMP"
ENDSSH

if [[ $? -ne 0 ]]; then
    echo "❌ ERRO ao gerar dump no PythonAnywhere"
    exit 1
fi

echo ""
echo "========================================="
echo "FASE 2: Download do Dump"
echo "========================================="

# Criar diretório local se não existir
mkdir -p "$LOCAL_DUMP_DIR"

# Download via SCP
echo "📥 Baixando dump para local..."
scp "$PA_USERNAME@$PA_HOSTNAME:$REMOTE_TEMP_DUMP" "$LOCAL_DUMP_FILE"

if [[ $? -ne 0 ]]; then
    echo "❌ ERRO ao baixar dump"
    # Limpar arquivo temporário no PythonAnywhere
    ssh "$PA_USERNAME@$PA_HOSTNAME" "rm -f $REMOTE_TEMP_DUMP"
    exit 1
fi

echo "✅ Dump baixado: $LOCAL_DUMP_FILE"

# Limpar arquivo temporário no PythonAnywhere
echo "🧹 Limpando arquivo temporário no PythonAnywhere..."
ssh "$PA_USERNAME@$PA_HOSTNAME" "rm -f $REMOTE_TEMP_DUMP"

echo ""
echo "========================================="
echo "FASE 3: Restaurar no Banco Local"
echo "========================================="

# Desconectar usuários e dropar banco
echo "⚠️  Encerrando conexões e dropando banco local..."
psql -U "$PG_LOCAL_USER" -h "$PG_LOCAL_HOST" -p "$PG_LOCAL_PORT" -d postgres << ENDSQL
-- Encerrar conexões ativas
SELECT pg_terminate_backend(pg_stat_activity.pid)
FROM pg_stat_activity
WHERE pg_stat_activity.datname = '$PG_DATABASE'
  AND pid <> pg_backend_pid();

-- Dropar banco
DROP DATABASE IF EXISTS $PG_DATABASE;

-- Recriar banco
CREATE DATABASE $PG_DATABASE;
ENDSQL

if [[ $? -ne 0 ]]; then
    echo "❌ ERRO ao dropar/criar banco local"
    exit 1
fi

echo "✅ Banco local recriado"

# Restaurar dump
echo ""
echo "📦 Restaurando dump no banco local..."
psql -U "$PG_LOCAL_USER" -h "$PG_LOCAL_HOST" -p "$PG_LOCAL_PORT" -d "$PG_DATABASE" < "$LOCAL_DUMP_FILE"

if [[ $? -ne 0 ]]; then
    echo "❌ ERRO ao restaurar dump"
    exit 1
fi

echo "✅ Dump restaurado com sucesso"

# Verificar dados
echo ""
echo "🔍 Verificando dados importados..."
DESPESAS_COUNT=$(psql -U "$PG_LOCAL_USER" -h "$PG_LOCAL_HOST" -p "$PG_LOCAL_PORT" -d "$PG_DATABASE" -t -c "SELECT COUNT(*) FROM despesas;" | xargs)
GRUPOS_COUNT=$(psql -U "$PG_LOCAL_USER" -h "$PG_LOCAL_HOST" -p "$PG_LOCAL_PORT" -d "$PG_DATABASE" -t -c "SELECT COUNT(*) FROM grupos;" | xargs)

echo ""
echo "========================================="
echo "   ✅ SINCRONIZAÇÃO CONCLUÍDA!"
echo "========================================="
echo "📊 Dados importados:"
echo "   • Despesas: $DESPESAS_COUNT"
echo "   • Grupos: $GRUPOS_COUNT"
echo ""
echo "💾 Dump salvo em:"
echo "   $LOCAL_DUMP_FILE"
echo ""
echo "🎯 Banco local agora está idêntico à produção"
echo "========================================="
