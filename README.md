![Bash-Transparent](https://github.com/user-attachments/assets/e098e106-9b50-430d-bf9c-0f7e42369f66)

# Features
The installer can be used to install project dependencies and handle venv setup for python projects. Packages can be included by adding to lists in the script or by including a python and/or system dependencies file.
- Customizable ASCII console display with logo compatibility.
- ASCII color mode toggle.
- Update system (debian-based linux) dependencies with a dependency file or array.
- Create and update python3-venv dependencies with a dependency file or array.
- Recieve a colorful realtime update of what is installing and any errors.
- Re-run to install all missing dependencies without attempting to re-install present ones.
- Well commented and organized code , easy to modify and understand.

# Gallery
![InstallerPreview1](https://github.com/user-attachments/assets/3b38f4bc-c1f0-4fae-aa8a-1568c20e7df3)
![InstallerPreview2](https://github.com/user-attachments/assets/44c9ab43-3474-4c5a-a34c-87dd1ad83550)

___

# Usage
There are two ways to install dependencies with the installation script. One can either make use of the dependency list variables, or can put dependency files in the script directory and enable usage of them.
Both will report progress and importantly, both methods result in the same experience.
___
# Using Dependency Lists
Within the installation file, there are multiple variables allowing for addition of dependencies. Both Python3 and system dependencies can be installed in this manner.

### selecting option
in order to select lists as your option for installation, make sure 'USE_CORE_TXT' for system dependencies and 'USE_PY_TXT' for python dependencies are both set to 0.
example:
USE_PY_TXT=0
USE_CORE_TXT=0


### customize the following for your needs
CORE_DEP (dependencies for system here)
CORE_CFG (commands for after installing system dependencies here)
PY_DEP (python libraries to install into the venv here)
PY_CFG (system commands to run after the python libraries are installed here)

___
# USING DEPENDENCY/CONFIGURATION FILES
### selecting option
in order to select files as your option for installation, make sure 'USE_CORE_TXT' for system dependencies and 'USE_PY_TXT' for python dependencies are both set to 1. The 'USE_CONFIG_TXT' can be used to run a file containing configuration commands after installs but before python setup.
example:
- USE_PY_TXT=1
- USE_CORE_TXT=1
- USE_CONFIG_TXT=1

#### making the dependency/configuration files
- CORE_TXT: the name of the file that stores system dependencies in the script directory
- PY_TXT: the name of the file that stores python dependencies in the script directory
- USE_CONFIG_TXT: the name of the file that stores bash configuration commands in the script directory

### adding dependencies/configuration
in the 'CORE_TXT', 'USE_CONFIG_TXT' and 'PY_TXT' files created previously, add one dependency or command per line.

### customize the following for your needs
- CORE_CFG (commands for after installing system dependencies here)
- PY_CFG (system commands to run after the python libraries are installed here)

___
# EXAMPLES

### Install with dependency lists
```sh
STARTUPGREETER=1  # if the greeter should be printed at launch
PROGRAM="Bellamy-Test"  # your program name
VERSION="0.2"  # your program version
VENVNAME="venv"  # your venv name
FINAL_NOTE="Completed Installing, run with 'run.sh'"
CLEAR_CONSOLE=1

# enable/disable core features
SETUP_PY=1  # if 0, will not setup python venv or install python packages
USE_CORE_TXT=0  # if a requirements file should be used to install sytem dependencies
USE_CONFIG_TXT=0  # if a file should be used to run configuration commands instead of the array
USE_PY_TXT=0  # if set to 1, will use a requirements.txt file to install python dependencies
COLORFUL=1  # set to 0 if no ansi colors are wanted for the terminal output

# filenames
LOGNAME="install.log"
PY_TXT="python3-requirements.txt"  # filename of the python requirements (pip formatting)
CORE_TXT="linux-requirements.txt"  # filename of apt requirements (one package per line, unquoted)
CONFIG_TXT="linux-configurations.txt"  # filename of bash configuration command list (one command per line, unquoted)

# system packages to by installed (apt-get/apt repo)
CORE_DEP=('zenity', 'htop', 'neofetch') 
# any commands that should be run directly after system package installs
CORE_CFG=('mkdir config' 'touch config/fakeprogram.config')
# python3 packages to be installed into the virtual environment
PY_DEP=('pillow' 'bs4' 'requests')
# any commands that should be run directly after pip installations
PY_CFG=('mkdir pycache')
```

### Install with dependency files
```sh
STARTUPGREETER=1  # if the greeter should be printed at launch
PROGRAM="Bellamy-Test"  # your program name
VERSION="0.2"  # your program version
VENVNAME="venv"  # your venv name
FINAL_NOTE="Completed Installing, run with 'run.sh'"
CLEAR_CONSOLE=1

# enable/disable core features
SETUP_PY=1  # if 0, will not setup python venv or install python packages
USE_CORE_TXT=1  # if a requirements file should be used to install sytem dependencies
USE_CONFIG_TXT=1  # if a file should be used to run configuration commands instead of the array
USE_PY_TXT=1  # if set to 1, will use a requirements.txt file to install python dependencies
COLORFUL=1  # set to 0 if no ansi colors are wanted for the terminal output

# filenames
LOGNAME="install.log"
PY_TXT="python3-requirements.txt"  # filename of the python requirements (pip formatting)
CORE_TXT="linux-requirements.txt"  # filename of apt requirements (one package per line, unquoted)
CONFIG_TXT="linux-configurations.txt"  # filename of bash configuration command list (one command per line, unquoted)

# system packages to by installed (apt-get/apt repo)
CORE_DEP=()
# any commands that should be run directly after system package installs
CORE_CFG=('mkdir config' 'touch config/fakeprogram.config')
# python3 packages to be installed into the virtual environment
PY_DEP=()
# any commands that should be run directly after pip installations
PY_CFG=()

# linux-requirements.txt
zenity
htop
neofetch

# python3-requirements.txt
pillow
bs4
requests

# linux-configurations.txt
mkdir config
touch config/fakeprogram.config
```
___
Programmer: Caleb Tash
