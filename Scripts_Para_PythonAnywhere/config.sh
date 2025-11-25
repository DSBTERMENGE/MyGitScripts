#!/usr/bin/env bash

# =========================================================================
# CONFIGURAÇÃO - PythonAnywhere
# =========================================================================

# Credenciais PythonAnywhere
PA_USERNAME="davidbit"
PA_HOSTNAME="ssh.pythonanywhere.com"

# Paths no PythonAnywhere
PA_HOME="/home/davidbit"
PA_SCRIPTS_DIR="$PA_HOME/scripts"

# Repositórios a atualizar (array)
declare -a PA_REPOS=(
    "$PA_HOME/framework_dsb/backend"
    "$PA_HOME/framework_dsb/frontend"
    "$PA_HOME/FinCtl"
)

# Webapp
PA_WEBAPP="davidbit.pythonanywhere.com"

# Branches
DEFAULT_BRANCH="developer"
PRODUCTION_BRANCH="master"

# Path local deste script
SCRIPT_DIR="C:/Applications_DSB/Scripts_Para_Git/Scripts_Para_PythonAnywhere"
