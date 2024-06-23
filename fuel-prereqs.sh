#!/bin/bash

FUEL_SPOOF_DIR="$(dirname "$(realpath "$0")")"
# Add color echoes
which red_echo &>/dev/null ||
  source "${FUEL_SPOOF_DIR}/color-echo.sh"

# Check if python3 is installed
python_path=''
if sudo command -v python &> /dev/null; then
      py_version=$(sudo python --version | sed -E 's/^Python *//')
      if [[ $py_version == "3."* ]]; then
        python_path="$(sudo which python)"
      fi
fi
sudo test -x "$python_path" ||
if sudo command -v python3 &> /dev/null; then
    # Store the Python path using sudo
    python_path=$(sudo which python3)
    #echo "Python path: $python_path"
fi

if ! sudo test -x "$python_path"; then
    red_echo "python3 not found"
    yellow_echo "Please install Python"
    exit 1
fi

# Check if pymobiledevice3 is installed
# Check if the module is installed
if ! sudo "$python_path" -m pip show pymobiledevice3 &>/dev/null; then
    cmd="$python_path -m pip install pymobiledevice3"
    try_sudo_install='false'
    red_echo "ERROR: pymobiledevice3 not found"
    yellow_echo "Please install using either:\n"
    magenta_echo "\t$cmd     \t# [1] Run as current user"
    magenta_echo "\tsudo $cmd\t# [2] Run as super user"
    yellow_echo -n "\nRun command as current user? ([y]|n): "
    read install_pmd3
    case $install_pmd3 in
      ''|y*)
        magenta_echo "> $cmd"
        eval "$cmd"
        err=$?
        test $err -gt 0 &&
          try_sudo_install='true' &&
          red_echo "ERROR: Standard install failed - code <$err>"
        ;;
      *)
        try_sudo_install='true'
    esac
    [[ "$try_sudo_install" == 'true' ]] &&
    yellow_echo -n "\nRun command as super user? ([y]|n): "
    read sudo_install_pmd3
    case $sudo_install_pmd3 in
      ''|y*)
        magenta_echo "> sudo $cmd"
        sudo eval "$cmd"
        err=$?
        test $err -gt 0 &&
          red_echo "ERROR: Root install failed - code <$err>"
        ;;
    esac

  test -n "${install_pmd3}${sudo_install_pmd3}" &&
  sudo "$python_path" -m pip show pymobiledevice3 &>/dev/null
  err=$?
  test $err -gt 0 &&
    red_echo "ERROR: pymobiledevice3 failed to install" &&
    exit $err
fi

# Check if jq is installed
if ! command -v jq &>/dev/null; then
    echo "jq not found"
    echo "Please install jq"
    brew_exe=$(which brew 2>/dev/null)
    if test -x "$brew_exe"; then
      yellow_echo "This is the install command using $brew_exe\n"
      magenta_echo "$brew_exe install jq"
      yellow_echo -n "Run this command ([y]|n): "
      read install_jq
      case $install_jq in
        ''|y*)
          magenta_echo "> $brew_exe install jq"
          "$brew_exe" install jq
          ;;
      esac
    fi
  command -v jq &>/dev/null
  err=$?
  if test $err -gt 0; then
    red_echo "ERROR: jq failed to install"
    exit 1
  fi
fi

