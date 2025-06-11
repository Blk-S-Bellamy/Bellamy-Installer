#!/bin/bash
# initialize installation in correct directory
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}" > /dev/null 2>&1

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# CONFIGURATION VARIABLES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

STARTUPGREETER=1  # if the greeter should be printed at launch
PROGRAM="Bellamy-Test"
VERSION="0.2"
VENVNAME="venv"
FINAL_NOTE="Completed Installing, run with 'run.sh'"
CLEAR_CONSOLE=1

# enable/disable core features
SETUP_PY=1  # if 0, will not setup python venv or install python packages
USE_CORE_TXT=1  # if a requirements file should be used to install sytem dependencies
USE_CONFIG_TXT=1  # if a file should be used to run configuration commands instead of the array
USE_PY_TXT=0  # if set to 1, will use a requirements.txt file to install python dependencies
COLORFUL=1  # set to 0 if no ansi colors are wanted for the terminal output

# filenames
LOGNAME="install.log"
PY_TXT="python3-requirements.txt"  # filename of the python requirements (pip formatting)
CORE_TXT="linux-requirements.txt"  # filename of apt requirements (one package per line, unquoted)
CONFIG_TXT="linux-configurations.txt"  # filename of bash configurations (one command per line, unquoted)

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# CONFIGURE DEPENDENCIES 
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
# COLOR ANSI CODES
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

spinner=('|' '/' '-' '\\')  # spinner animation characters
DATETIME=$(date +"%Y-%m-%d %H:%M:%S")
# EPOCH=$(date +"%H:%M:%S.%3N")
LOG_DATETIME="$DATETIME"
PHYSLOG="$SCRIPT_DIR/$LOGNAME"  # log used to document the installation

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# NOTIFICATION PREFIXES
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

back="\r\033[0K" 
check="\n${YELLOW}|░░CHECKING░░${YELLOW}>"  
installing="${back}${YELLOW}|░░INSTALLING░░${YELLOW}>"
error="${back}${RED}|░░PACKAGE-ERROR░░${YELLOW}>"
installererror="${back}${RED}|░░SETUP-ERROR░░${YELLOW}>"
satisfied="${back}${MAGENTA}|░░DEPENDENCY-SATISFIED░░${YELLOW}>"
configured="${back}${MAGENTA}|░░CONFIGURED░░${YELLOW}>"
updating="\n${RED}|░░UPDATING...░░${YELLOW}>"
creating="${back}${YELLOW}|░░CREATING...░░${YELLOW}>"
loaded="\n${MAGENTA}|░░LOADED...░░${YELLOW}>"
running="\n${YELLOW}|░░RUNNING..░░${YELLOW}>"
ran="${back}${MAGENTA}|░░RAN..░░${YELLOW}>"
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
${YELLOW}[by installing you agree to all terms present in documentation]
"""
HEADER="${MAGENTA}${PROGRAM}${VERSION} Installer ${YELLOW}>>${MAGENTA} "

ENDER="""\n${MAGENTA}⣿${CYAN}¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤${MAGENTA}⣿
${FINAL_NOTE}
⣿${CYAN}¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤¤${MAGENTA}⣿
"""

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# INSTALLER CORE FUNCTIONS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# 1=event
function log_event {
    # cut out the ansi escape sequences before logging lol
    echo "[$LOG_DATETIME | PID=$$] $1" >> $PHYSLOG
}

# capture sudo in bash instance for the installation
function capture_sudo {
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

# checks for failures and prints/logs issue
function filecheck {
    # check if a file exists
    if [ ! -f "$1" ]; then
        log_event "[CRITICAL] \"$2\": installation will now terminate..."
        printf "${installererror} \"$2\":\n!! to terminate installation, press enter..."
        read
        exit
    fi
}

# make sure all needed components are present before installing
function prechecks {
    if [ $USE_CORE_TXT -eq 1 ]; then
        filecheck "$CORE_TXT" "unable to find \"$CORE_TXT\" for core dependencies"
    fi

    if [ $USE_CONFIG_TXT -eq 1 ]; then
        filecheck "$CONFIG_TXT" "unable to find \"$CONFIG_TXT\" for configurations"
    fi

    if [ $USE_PY_TXT -eq 1 ]; then
        filecheck "$PY_TXT" "unable to find \"$PY_TXT\" for pip-python3 packages"
    fi
}

# animated spinner to show things are happening :3
function spinner {
    sp="|/-\ "
    local i=0
    # Hide cursor
    tput civis
    # spin (WEEEEEEEEEEEEEE)
    while :; do
        printf "${YELLOW}\r%s" "${sp:i++%${#sp}:1}"
        sleep 0.1
  done
}

function start_spinner {
    spinner &
    spinner_pid=$!
}

function stop_spinner {
    kill "$spinner_pid" >/dev/null 2>&1
    printf "\r \r"
    tput cnorm
}

function clear_term {
    if [ $CLEAR_CONSOLE -eq 1 ]; then
        clear
    fi 
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# EXIT CODE HANDLERS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# maps codes to common errors to a message for apt installs
# 1='package or action'
function core_codes {
    local code=$?
    if [[ "$code" == "$code" ]]; then
       printf "${error}[code-$code] ${CYAN} cannot locate package... \"$1\""
       log_event "[code-$code] cannot locate package... \"$1\"" 
    elif [[ "$code" == "0" ]]; then
        printf "${satisfied}[code-$code] ${CYAN}$1"
        log_event "[code-$code] installed package... \"$1\"" 
    else
        printf "${satisfied} ${CYAN}$1"
        log_event "[code-$code] installed package... \"$1\"" 
    fi
}

# maps codes to common errors to a message for core config commands
# 1='package or action'
function core_config_codes {
    local code=$?
    # determine code and give feedback/log results 
    if [[ "$code" == "127" ]]; then
       printf "${error} [code-$code] ${CYAN} command not found \"$1\" ${LGREY}(system-configuration)"
       log_event "[code-$code] command not found \"$1\""
    elif [[ "$code" == "0" ]]; then
        printf "${ran} [code-$code] ${CYAN} executed command \"$1\" ${LGREY}(system-configuration)"
        log_event "[code-$code] executed command \"$1\"" 
    else
        printf " [code-$code] ${ran} ${CYAN} executed command \"$1\" ${LGREY}(system-configuration)"
        log_event "[code-$code] executed command \"$1\"" 
    fi
}

# maps codes to common errors to a message for 'pip install' commands
# 1='package or action'
function py_codes {
    local code=$?
    # determine code and give feedback/log results 
    if [[ "$code" == "1" ]]; then
       printf "${error} [code-$code] ${CYAN} pip cannot find package \"$1\" ${LGREY}(pip-python3)"
       log_event "[code-$code] pip cannot find package \"$1\""
    elif [[ "$code" == "0" ]]; then
        printf "${satisfied} [code-$code] ${CYAN} installed package \"${element}\" ${LGREY}(pip-python3)"
        log_event "[code-$code] installed package \"$1\""
    else
        printf "${satisfied} ${CYAN} warning, unknown exit code for package install \"${element}\" ${LGREY}(pip-python3)"
        log_event "[code-$code] warning, unknown exit code for package install \"$1\""
    fi
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# CORE DEPENDENCIES INSTALLERS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# iterate linux dependencies and install them
function install_dependencies {
    # core dependencies
    # will load dependencies from the in-script variabless
    for element in "${CORE_DEP[@]}"; do
        printf "${check} ${CYAN}${element}"
        if dpkg -s "$element" &> /dev/null; then
            printf "${satisfied} ${CYAN}${element}"
            log_event "dependency is satisfied already\"$element\""
        else
            printf "${installing} ${CYAN}${element}" && start_spinner
            sudo apt-get install "${element}" -y > /dev/null 2>&1

            # handle the error codes and print the result
            result=$(core_codes "$element")
            stop_spinner
            printf "$result"
            

            
        fi
    done

    # used to terminate before file check
    if [[ "$1" -eq "1" ]]; then
        return
    fi

    # will load dependencies from a file too
    if [ $USE_CORE_TXT -eq 1 ]; then
        while IFS= read -r line; do
            printf "${check} ${CYAN}${line}"
            if dpkg -s "$line" &> /dev/null; then
                printf "${satisfied} ${CYAN}${line}"
                log_event "dependency is satisfied already... \"$line\""
            else
                printf "${installing} ${CYAN}${line}" && start_spinner
                sudo apt-get install "${line}" -y > /dev/null 2>&1

                # handle the error codes and print the result
                result=$(core_codes "$line")
                stop_spinner
                printf "$result"
            fi
        done < "$CORE_TXT"
    fi
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# CORE DEPENDENCIES CONFIGURATIONS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# if configuration is needed, these can be run after all dependencies are run
function configure_core {
    for element in "${CORE_CFG[@]}"; do
        printf "${running} ${CYAN}${element} ${LGREY}(system-configuration)" && start_spinner
        eval "$element" > /dev/null 2>&1

        result=$(core_config_codes "$element")
        stop_spinner
        printf "$result"
    done

    # will load dependencies from a file too
    if [ $USE_CONFIG_TXT -eq 1 ]; then
        while IFS= read -r line; do
            printf "${running} ${CYAN}${line} ${LGREY}(system-configuration)" && start_spinner
            eval "$line" > /dev/null 2>&1
        
            # handle the error codes and print the result
            result=$(core_config_codes "$line")
            stop_spinner
            printf "$result"
        done < "$CONFIG_TXT"
    fi
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# PYTHON DEPENDENCY INSTALLERS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# creates a new venv if it does not exist
function install_venv {
    printf "${check} ${CYAN}\"$VENVNAME\" virtual environment status"
    if [ ! -f "${VENVNAME}/bin/activate" ]; then
        printf "${creating} ${CYAN}virtual environment \"$VENVNAME\"" && start_spinner
        python3 -m venv ${VENVNAME} > /dev/null 2>&1 # create a virtual environment if one does not exist
        stop_spinner
        printf "${satisfied} ${CYAN}\"$VENVNAME\" virtual environment was created"
        log_event "\"$VENVNAME\" virtual environment was created"
    else
        printf "${satisfied} ${CYAN}virtual environment exists"
        log_event "\"$VENVNAME\" virtual environment exists"
    fi
}


# installs the python dependencies by dictionary or requirements file
function install_py_dependencies {
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

            # handle the error codes and print the result
            result=$(py_codes "$element")
            stop_spinner
            printf "$result"
    done
    fi
}

#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#
# PYTHON CONFIGURATIONS
#-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-:-#

# will run any python configuration commands that are needed
function configure_py {
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

function install {
    clear_term  # will clear the terminal if selected
    # optional greeter header
    if [ $STARTUPGREETER -eq 1 ]; then
        printf "$GREETER"
    fi
    printf "${HEADER}"
    # will terminate early if the needed files are not created
    prechecks
    
    capture_sudo  # make sure bash instance has sudo access for installs
    printf "\n${YELLOW}[${LGREY}installing linux dependencies...${YELLOW}]${NC}"
    install_dependencies  # install linux dependencies
    printf "\n${YELLOW}[${LGREY}starting linux configurations...${YELLOW}]${NC}"
    configure_core  # configure linux dependencies

    # will setup python with needed packages if requested
    if [ $SETUP_PY -eq 1 ]; then
        # install needed python packages to setup environment
        printf "\n${YELLOW}[${LGREY}starting python setup...${YELLOW}]${NC}"
        CORE_DEP=("python3" "python3-venv" "python3-pip")
        install_dependencies 1
        install_venv  # create a venv if it does not exist
        install_py_dependencies  # activate venv and install all python dependencies
        configure_py  # apply any needed post 'pip install' configurations
    else
        printf "\n${YELLOW}[${LGREY}skipping python setup${YELLOW}]${NC}"
    fi
    printf "${ENDER}${YELLOW}[${LGREY}bellamy-installer 0.2${YELLOW}]${NC}"
    printf "\n"  # prevents newline from landing on the end of the last line
}

# main installation function
install
