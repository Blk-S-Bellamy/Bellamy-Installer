#!/bin/bash
# initialize installation in correct directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" > /dev/null 2>&1

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# INSTALLATION VARIABLES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

PROGRAM=""
VERSION=""
VENVNAME="venv"
FINAL_NOTE="Completed Installing, run with 'run.sh'"
CLEAR_CONSOLE=1

STARTUPGREETER=1  # if the greeter should be printed at launch
USE_CORE_TXT=0  # if a requirements file should be used to install sytem dependencies
CORE_TXT="linux-requirements.txt"
USE_PY_TXT=0  # if set to 1, will use a requirements.txt file to install python dependencies
PY_TXT="python3-requirements.txt"  # filename of the python requiremets (pip formatting)
COLORFUL=1

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# DEPENDENCIES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# system packages to by installed (apt-get/apt repo)
CORE_DEP=()
# any commands that should be run directly after system package installs
CORE_CFG=()
# python3 packages to be installed into the virtual environment
PY_DEP=()
# any commands that should be run directly after pip installations
PY_CFG=()

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# COLOR EXIT CODES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# sets initial colors if not set to be default
RED='\033[0;31m'
GREEN='\033[0;32m'
MAGENTA='\033[0;95m'
CYAN='\033[0;36m'
ORANGE='\033[0;33m'
YELLOW='\033[0;93m'
LGREY="\e[37m"
NC='\033[0m'

# disables chat colors if option is set
if [ $COLORFUL -eq 0 ]; then
    RED=${NC}
    GREEN=${NC}
    MAGENTA=${NC}
    CYAN=${NC}
    ORANGE=${NC}
    YELLOW=${NC}
    LGREY=${NC}
fi

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# MISC VARIABLES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

spinner=('|' '/' '-' '\\')

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# NOTIFICATION PREFIXES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

back="\r\033[0K" ${back}
check="\n${YELLOW}|░░CHECKING░░${YELLOW}>"  
installing="${back}${YELLOW}|░░INSTALLING░░${YELLOW}>"
satisfied="${back}${MAGENTA}|░░DEPENDENCY-SATISFIED░░${YELLOW}>"
configured="${back}${MAGENTA}|░░CONFIGURED░░${YELLOW}>"
updating="\n${RED}|░░UPDATING...░░${YELLOW}>"
creating="${back}${YELLOW}|░░CREATING...░░${YELLOW}>"
loaded="\n${MAGENTA}|░░LOADED...░░${YELLOW}>"
running="\n${YELLOW}|░░RUNNING..░░${YELLOW}>"
extracting="\n${MAGENTA}|░░EXTRACTING...░░${YELLOW}>"

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# PRINTABLES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# can e changed to be an ASCII logo or text
GREETER="""${MAGENTA}⣿${CYAN}¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤${MAGENTA}⣿
|         __          |
|      -=(¤ '.        |
|         '.-.\       |
|         /|  \\\\\      |
|         '|  ||      |
|          ▄\_):,     |
⣿${CYAN}¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤${MAGENTA}⣿
[by installing you agree to all terms present in documentation]
"""
HEADER="${MAGENTA}${PROGRAM}${VERSION} Installer ${YELLOW}>>${MAGENTA} "

ENDER="""\n${MAGENTA}⣿${CYAN}¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤${MAGENTA}⣿
${FINAL_NOTE}
⣿${CYAN}¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤${MAGENTA}⣿
"""

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# INSTALLER CORE FUNCTIONS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# capture sudo in bash instance for the installation
function capture_sudo () {
    local captured=0
    local tries=0
    while [ $captured -eq 0 ]; do
        # Alternatively, check sudo access allowing password prompt (interactive)
        if sudo -v 2>/dev/null; then
            captured=1
            printf "(sudo satisfied)"
        else
            if [ $tries -eq 1 ]; then
                printf "${YELLOW}sudo not captured, terminating${RED}....\n"
                exit
            fi
        fi


        tries=$((tries+=1))
    done
}

# animated spinner to show things are happening :3
function spinner() {
    sp="|/-\ "
    local i=0
    # Hide cursor
    tput civis
    while :; do
        printf "\r%s" "${sp:i++%${#sp}:1}"
        sleep 0.1
  done
}

function start_spinner () {
    spinner &
    spinner_pid=$!
}

function stop_spinner () {
    kill "$spinner_pid" >/dev/null 2>&1
    printf "\r \r"
    tput cnorm
}


function clear_term () {
    if [ $CLEAR_CONSOLE -eq 1 ]; then
        clear
    fi 
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# CORE DEPENDENCIES INSTALLERS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# iterate linux dependencies and install them
function install_dependencies () {
    # core dependencies
    CORE_DEP+=("python3" "python3-venv" "python3-pip")
    # will load dependencies from the in-script variabless
    for element in "${CORE_DEP[@]}"; do
        printf "${check} ${CYAN}${element}"
        if dpkg -s "$element" &> /dev/null; then
            printf "${satisfied} ${CYAN}${element}"
        else
            printf "${installing} ${CYAN}${element}" && start_spinner
            sudo apt-get install "${element}" -y > /dev/null 2>&1
            stop_spinner
            printf "${satisfied} ${CYAN}${element}"
        fi
    done

    # will load dependencies from a file too
    if [ $USE_CORE_TXT -eq 1 ]; then
        while IFS= read -r line; do
            printf "${check} ${CYAN}${line}"
            if dpkg -s "$line" &> /dev/null; then
                printf "${satisfied} ${CYAN}${line}"
            else
                printf "${installing} ${CYAN}${line}" && start_spinner
                sudo apt-get install "${line}" -y > /dev/null 2>&1
                stop_spinner
                printf "${satisfied} ${CYAN}${line}"
            fi
        done < "$CORE_TXT"
    fi
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# CORE DEPENDENCIES CONFIGURATIONS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# if configuration is needed, these can be run after all dependencies are run
function configure_core () {
    for element in "${CORE_CFG[@]}"; do
        printf "${running} ${CYAN}${element} ${LGREY}(system-configuration)" && start_spinner
        eval "$element" > /dev/null 2>&1
        stop_spinner
        printf "${configured} ${CYAN}${element} ${LGREY}(system-configuration)"
    done
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# PYTHON DEPENDENCY INSTALLERS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# creates a new venv if it does not exist
function install_venv () {
    printf "${check} ${CYAN}virtual environment status"
    if [ ! -f "${VENVNAME}/bin/activate" ]; then
        printf "${creating} ${CYAN}virtual environment status" && start_spinner
        python3 -m venv ${VENVNAME} > /dev/null 2>&1 # create a virtual environment if one does not exist
        stop_spinner
        printf "${satisfied} ${CYAN}virtual environment exists"
    else
        printf "${satisfied} ${CYAN}virtual environment exists"
    fi
}


# installs the python dependencies by dictionary or requirements file
function install_py_dependencies () {
    printf "${loaded} ${CYAN}"${VENVNAME}"/bin/activate virtual environment"
    source "${VENVNAME}/bin/activate"
    if [ $USE_PY_TXT -eq 1 ]; then
        printf "${installing} ${CYAN}${PY_TXT}" && start_spinner
        pip install -r ${PY_TXT} > /dev/null 2>&1
        stop_spinner
        printf "${satisfied} ${CYAN}${PY_TXT} dependencies"
    else
        for element in "${PY_DEP[@]}"; do
            printf "${updating} ${CYAN}${element}" && start_spinner
            pip install "$element" > /dev/null 2>&1
            stop_spinner
            printf "${satisfied} ${CYAN}python3-${element}"
        done
    fi
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# PYTHON CONFIGURATIONS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# will run any python configuration commands that are needed
function configure_py () {
    for element in "${PY_CFG[@]}"; do
        printf "${running} ${CYAN}${element} ${LGREY}(python3-configuration)" && start_spinner
        eval "$element" > /dev/null 2>&1
        stop_spinner
        printf "${configured} ${CYAN}${element} ${LGREY}(python3-configuration)"
    done
}


#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# MAIN LOGIC
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

function install () {
    clear_term  # will clear the terminal if selected
    # optional greeter header
    if [ $STARTUPGREETER -eq 1 ]; then
        printf "$GREETER"
    fi
    printf "${HEADER}"
    
    capture_sudo  # make sure bash instance has sudo access for installs
    install_dependencies  # install linux dependencies
    configure_core  # configure linux dependencies
    install_venv  # create a venv if it does not exist
    install_py_dependencies  # activate venv and install all python dependencies
    configure_py  # apply any needed post 'pip install' configurations
    printf "${ENDER}${YELLOW}[${LGREY}bellamy-installer 0.1${YELLOW}]${NC}"
    printf "\n"  # prevents newline from landing on the end of the last line
}


# main installation function
install
