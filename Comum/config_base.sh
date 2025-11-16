#!/usr/bin/env bash

# =============================
# CONFIGURAÇÃO BASE COMPARTILHADA
# =============================
# Este arquivo contém configurações comuns a TODOS os scripts
# Para usar em outros scripts, adicione no início:
# source "$(dirname "${BASH_SOURCE[0]}")/../Comum/config_base.sh"

# --- Identificação da Máquina e Subpasta de Backup ---
MACHINE_ID="$(hostname | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/_/g')"

# Detectar máquina e definir subpasta
case "$MACHINE_ID" in
    "dsb_asus")
        BACKUP_SUBDIR="dsb_asus"
        ;;
    "administrator") 
        BACKUP_SUBDIR="administrator"
        ;;
    *)
        echo "❌ [ERRO] Nome do computador '$MACHINE_ID' não reconhecido!"
        echo "💡 Subpastas disponíveis: dsb_asus, administrator"
        echo "💡 Nome atual do computador: $MACHINE_ID"
        exit 1
        ;;
esac

MACHINE_TIMESTAMP="$(date +"%Y%m%d_%H%M%S")"

# --- Configurações Git ---
DEFAULT_BRANCH="developer"
PRODUCTION_BRANCH="master"  # Pode ser sobrescrito (ex: "merge" para Umbrella)

# --- Detecção do Google Drive ---
if [[ -d "G:/My Drive" ]]; then
    GOOGLE_DRIVE_PATH="G:/My Drive"
    GOOGLE_DRIVE_BASE="G:/My Drive/Applications_DSB_Copias"
    echo "🌐 Google Drive detectado (English): G:/My Drive"
elif [[ -d "G:/Meu Drive" ]]; then
    GOOGLE_DRIVE_PATH="G:/Meu Drive"
    GOOGLE_DRIVE_BASE="G:/Meu Drive/Applications_DSB_Copias"
    echo "🌐 Google Drive detectado (Português): G:/Meu Drive"
else
    echo "❌ ERRO: Google Drive não encontrado"
    echo "💡 Verifique se o Google Drive está instalado e sincronizado"
    exit 1
fi

echo "📁 Subpasta de backup: $BACKUP_SUBDIR"

# --- Logs (separados por máquina) ---
LOG_FILE="$HOME/dsb_git_scripts_${MACHINE_ID}.log"
