#!/usr/bin/env bash

# =========================================================================
# ATUALIZAR PRODUÇÃO - PythonAnywhere
# =========================================================================
# Script executado NO PythonAnywhere para atualizar código
# Pull developer + master nos 3 repos, deixa master ativo, reload webapp
# =========================================================================

set -e

# Configuração de log
LOG_FILE="$HOME/scripts/atualizar_producao.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Função de log (escreve no arquivo e na tela)
log() {
    echo "$1" | tee -a "$LOG_FILE"
}

# Função de log apenas para arquivo
log_only() {
    echo "$1" >> "$LOG_FILE"
}

# Inicializar log (sobrescreve arquivo anterior)
echo "=========================================" > "$LOG_FILE"
echo "   LOG DE ATUALIZAÇÃO - PythonAnywhere" >> "$LOG_FILE"
echo "=========================================" >> "$LOG_FILE"
echo "Data/Hora: $TIMESTAMP" >> "$LOG_FILE"
echo "=========================================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

log "========================================="
log "   ATUALIZAR PRODUÇÃO - PythonAnywhere"
log "========================================="
log ""
log "📅 Início: $TIMESTAMP"
log ""

# Repositórios a atualizar
REPOS=(
    "/home/davidbit/framework_dsb/backend"
    "/home/davidbit/framework_dsb/frontend"
    "/home/davidbit/FinCtl"
)

WEBAPP="davidbit.pythonanywhere.com"

log "📦 Repositórios a atualizar:"
for REPO in "${REPOS[@]}"; do
    log "   • $REPO"
done
log ""

# Loop pelos repositórios
REPO_COUNT=0
REPO_SUCCESS=0
REPO_ERRORS=0

for REPO in "${REPOS[@]}"; do
    REPO_COUNT=$((REPO_COUNT + 1))
    
    log "========================================"
    log "📂 Repositório [$REPO_COUNT/3]: $REPO"
    log "========================================"
    
    # Tentar mudar para o diretório
    if ! cd "$REPO" 2>> "$LOG_FILE"; then
        log "❌ ERRO: Não foi possível acessar $REPO"
        log_only "Erro ao executar: cd $REPO"
        REPO_ERRORS=$((REPO_ERRORS + 1))
        continue
    fi
    log_only "✓ Diretório acessado com sucesso"
    
    # Verificar working tree limpo
    STATUS_OUTPUT=$(git status --porcelain 2>> "$LOG_FILE")
    if [[ -n "$STATUS_OUTPUT" ]]; then
        log "❌ ERRO: Mudanças não commitadas em $REPO"
        log_only "$STATUS_OUTPUT"
        REPO_ERRORS=$((REPO_ERRORS + 1))
        exit 1
    fi
    log_only "✓ Working tree limpo"
    
    # Fetch
    log "🔄 Fetch..."
    if git fetch origin >> "$LOG_FILE" 2>&1; then
        log_only "✓ Fetch concluído com sucesso"
    else
        log "❌ ERRO ao fazer fetch"
        REPO_ERRORS=$((REPO_ERRORS + 1))
        continue
    fi
    
    # Pull developer
    log "⬇️  Pull developer..."
    if git checkout developer >> "$LOG_FILE" 2>&1 && git pull origin developer >> "$LOG_FILE" 2>&1; then
        COMMITS_DEV=$(git log --oneline -3 2>> "$LOG_FILE")
        log_only "✓ Developer atualizado"
        log_only "Últimos commits:"
        log_only "$COMMITS_DEV"
    else
        log "❌ ERRO ao atualizar developer"
        REPO_ERRORS=$((REPO_ERRORS + 1))
        continue
    fi
    
    # Pull master
    log "⬇️  Pull master..."
    if git checkout master >> "$LOG_FILE" 2>&1 && git pull origin master >> "$LOG_FILE" 2>&1; then
        COMMITS_MASTER=$(git log --oneline -3 2>> "$LOG_FILE")
        log_only "✓ Master atualizado"
        log_only "Últimos commits:"
        log_only "$COMMITS_MASTER"
    else
        log "❌ ERRO ao atualizar master"
        REPO_ERRORS=$((REPO_ERRORS + 1))
        continue
    fi
    
    log "✅ $REPO atualizado (master ativo)"
    REPO_SUCCESS=$((REPO_SUCCESS + 1))
    log ""
done

# Resumo dos repositórios
log "========================================"
log "📊 RESUMO DOS REPOSITÓRIOS:"
log "   Total: $REPO_COUNT"
log "   Sucesso: $REPO_SUCCESS"
log "   Erros: $REPO_ERRORS"
log "========================================"
log ""

# Reload webapp
log "========================================"
log "🔄 Recarregando webapp..."
if pa_reload_webapp.py "$WEBAPP" >> "$LOG_FILE" 2>&1; then
    log "✅ Webapp recarregado com sucesso"
    log_only "$(date '+%H:%M:%S') - Webapp reload concluído"
else
    log "⚠️  AVISO: Erro ao recarregar webapp"
    log_only "Erro no comando: pa_reload_webapp.py $WEBAPP"
fi
log ""

# Teste de saúde
log "🏥 Testando site..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://$WEBAPP" 2>> "$LOG_FILE")

if [[ "$HTTP_CODE" == "200" ]]; then
    log "✅ Site respondendo corretamente (HTTP $HTTP_CODE)"
    log_only "$(date '+%H:%M:%S') - Health check: OK"
else
    log "⚠️  Site retornou HTTP $HTTP_CODE"
    log_only "$(date '+%H:%M:%S') - Health check: FALHOU (HTTP $HTTP_CODE)"
fi

# Finalização
END_TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
log ""
log "========================================="
log "   ✅ ATUALIZAÇÃO CONCLUÍDA!"
log "========================================="
log "📦 Repositórios processados: $REPO_COUNT"
log "✅ Sucessos: $REPO_SUCCESS"
log "❌ Erros: $REPO_ERRORS"
log "🌐 Webapp: $WEBAPP"
log "📅 Término: $END_TIMESTAMP"
log "========================================="
log ""
log "📄 Log salvo em: $LOG_FILE"

# Resumo final apenas no log
log_only ""
log_only "========================================="
log_only "FIM DO LOG"
log_only "========================================="
