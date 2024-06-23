#!/bin/bash

export WAIT_API_REFRESH=300
export API_URL="https://projectzerothree.info/api.php?format=json"
export FUEL_TYPES=("E10" "U91" "U95" "U98" "Diesel" "LPG")
export REGIONS=('VIC' 'NSW' 'QLD' 'WA')

# FUEL_TEMP_FILE="$$-fuel-spoof.tmp"
FUEL_TEMP_FILE=".fuel-spoof.temp"
FUEL_SPOOF_DIR="$(dirname "$(realpath "$0")")"

# Check and delete temp file if it exists
test -e "${FUEL_TEMP_FILE}" &&
  rm "${FUEL_TEMP_FILE}"

exit_fuel_spoof() {
  if test $# -gt 0; then
    error_code=$1
    shift
  else
    error_code=0
  fi
  if test $# -gt 0; then
    >&2 echo "Exiting: $*"
  else
    >&2 echo "Exiting $0"
  fi
  test -e "${FUEL_TEMP_FILE}" &&
    cat "${FUEL_TEMP_FILE}" &&
    rm -f "${FUEL_TEMP_FILE}"
  exit $error_code
}

# Add color echoes
which red_echo &>/dev/null ||
  source "${FUEL_SPOOF_DIR}/color-echo.sh"

# check for prerequisites
source "${FUEL_SPOOF_DIR}/fuel-prereqs.sh"
source "${FUEL_SPOOF_DIR}/fuel-api.sh"

show_fuel_prices(){
  local fuel_types=($@)
  local best_option best_region best_price
  local fr_data price suburb state lat lng best_str
  local output
  test $# -gt 0 || fuel_types=(${FUEL_TYPES[@]})
  update_api_data || return $?

  echo -e "\n\n"
  for f in ${fuel_types[@]} ; do
    echo "$f Fuel Prices"
    best_option=$(echo "${API_DATA}" | jq -r '.regions[] | select(.region == "All").prices[] | select(.type == "'"$f"'")')
    best_region=$(echo "${best_option}" | jq -r '.state')
    best_price=$(echo "${best_option}" | jq -r '.price')
    output=''
    for r in ${REGIONS[@]}; do
      fr_data=$(echo "${API_DATA}" | jq -r '.regions[] | select(.region == "'"$r"'").prices[] | select(.type == "'"$f"'")')
      price=$(echo $fr_data | jq -r '.price')
      suburb=$(echo $fr_data | jq -r '.suburb')
      state=$(echo $fr_data | jq -r '.state')
      lat=$(echo $fr_data | jq -r '.lat')
      lng=$(echo $fr_data | jq -r '.lng')
      best_str="$([[ "$best_region" == "$state" ]] && echo -n "(BEST)")"
      output="${output}${price};${state};${suburb};${best_str}\n"
    done
    echo -e "${output}" | column -t -s';'
    echo -e "\n"
  done
}

# Present user with fuel options
echo_fuel_options() {
  local plural_str
  if test $# -gt 0; then plural_str='(s)'; fi
  echo "1) E10"
  echo "2) U91"
  echo "3) U95"
  echo "4) U98"
  echo "5) Diesel"
  echo "6) LPG"
  echo "e) Exit"
  echo -e "\n"
  yellow_echo -n "Enter your choice${plural_str} (1, 2, 3, 4, 5, 6 or e): "
}

eval_fuel_str() {
  local fuel_type
  while test $# -gt 0; do
    case $1 in
        1*)
            fuel_type="E10"
            ;;
        2*)
            fuel_type="U91"
            ;;
        3*)
            fuel_type="U95"
            ;;
        4*)
            fuel_type="U98"
            ;;
        5*)
            fuel_type="Diesel"
            ;;
        6*)
            fuel_type="LPG"
            ;;
        e*)
            echo "Exiting."
            exit_fuel_spoof 1
            ;;
        *)
            red_echo "Invalid fuel option. Exiting."
            exit_fuel_spoof 2
            ;;
    esac
    echo $fuel_type
    shift
  done
}

choose_fuel() {
  yellow_echo "\nSelect a fuel type:"
  echo_fuel_options
  read fuel_choice
  fuel_type=$(eval_fuel_str "${fuel_choice}")
}

choose_fuels() {
  yellow_echo "\nSelect your chosen fuel type(s):"
  echo_fuel_options plural
  read fuel_choices

  for fuel in 1 2 3 4 5 6; do
    [[ "${fuel_choices}" =~ "${fuel}" ]] && fuel_choice="${fuel_choice}${fuel}"
  done
  fuel_choices="${fuel_choice}"
}

echo_region_options() {
  local plural_str
  if test $# -gt 0; then plural_str='(s)'; fi
  echo "1) All (Best of all states)"
  echo "2) VIC"
  echo "3) NSW"
  echo "4) QLD"
  echo "5) WA"
  echo "e) Exit"
  echo -e "\n"
}

eval_region_str() {
  while test $# -gt 0; do
    case "$1" in
        1*)
            state_choice="All"
            ;;
        2*)
            state_choice="VIC"
            ;;
        3*)
            state_choice="NSW"
            ;;
        4*)
            state_choice="QLD"
            ;;
        5*)
            state_choice="WA"
            ;;
        e*)
            magenta_echo "Exiting."
            exit_fuel_spoof 1
            ;;
        *)
            red_echo "Invalid region. Exiting."
            exit_fuel_spoof 2
            ;;
    esac
    shift
  done
}

choose_regions() {
  yellow_echo "\nSelect the state(s) you wish to see:"
  echo_region_options plural
  read region_choices

  state_choice=''
  local state
  for state in 1 2 3 4 5; do
    [[ "${region_choices}" =~ "${state}" ]] && state_choice="${state_choice}${state}"
  done
  region_choices="${state_choice}"
}

# Present user with state options
choose_state() {
  yellow_echo "\nSelect a state:"
  echo_region_options
  yellow_echo -n "Enter your choice (1, 2, 3, 4, 5, 6 or e): "
  read state_choice

  # Assign the state based on the user's choice
  eval_region_str "${state_choice}"
}

choose_lock() {
  local lock_choice
  local fuel_str=" :Fuel Type:$(eval_fuel_str "${fuel_choice}")"
  local region_str=" :State:${state_choice}"
  local msg="$(echo -e "${fuel_str}\n${region_str}" | column -t -s':')"
  echo -e "You have selected\n${msg}"

  yellow_echo -n "Do you want to confirm your choices ([y]|n): "
  read lock_choice
  case $lock_choice in
    ''|y*)
      choice_lock='true'
      ;;
    *)
      choice_lock='false'
      magenta_echo "Selections for fuel & region have been reset"
      ;;
  esac
}

choose_fuel_preview() {
  choose_fuels
  fuel_choices="$(eval_fuel_str $(echo "${fuel_choices}" | grep -o '.') | tr '\n' ' ')"
  show_fuel_prices "${fuel_choices}"

}

magenta_echo \
"\n======== Welcome to iOS17 fuel spoofing =========
Fuel data sourced from projectzerothree.info
Requires pymobiledevice3 / python
Please consider buying me a coffee - Thank you!
=================================================\n"

declare fuel_choice state_choice

yellow_echo -n "Do you wish to preview fuel prices ([y]|n)? "
read preview_prices_choice
case $preview_prices_choice in
  ''|y*)
    magenta_echo '\nPreviewing Fuel Prices...'
    choose_fuel_preview
    echo -e '\nMake your final selection of location and fuel type.'
    ;;
  *)
    magenta_echo '\nSkipping fuel preview...'
    ;;
esac

choice_lock='false'
while [[ "${choice_lock}" != "true" ]]; do
  choose_fuel || exit_fuel_spoof $?
  choose_state || exit_fuel_spoof $?
  choose_lock
done

get_api_data $fuel_type $state_choice

# Execute Step 1 and save the output to a file
echo -e "Starting the tunnel - please wait..."
sudo $python_path -m pymobiledevice3 remote start-tunnel --script-mode > "${FUEL_TEMP_FILE}" &
# Give Step 1 some time to start before proceeding
#sleep 20

# Wait until temp file has some text
while [[ ! -s "${FUEL_TEMP_FILE}" ]]; do
    sleep 1
done


# Combine RSD Address and RSD Port
rsd_data=$(head -n 1 "${FUEL_TEMP_FILE}")

echo -e "\nDevice RSD data is: $rsd_data"


# Step 2 - Mount developer image
echo -e "\nMounting the developer image\n"
sudo $python_path -m pymobiledevice3 mounter auto-mount

# Step 4 - spoof location
echo -e "\nLocation Simulation is now running\n"
echo -e "Spoofing location to ($location)"
echo -e "You can now open your app and your location will be simulated"

# full_command="sudo $python_path -m pymobiledevice3 developer dvt simulate-location set --rsd $rsd_data -- $location"
# echo $full_command
# $full_command
#echo -e "\nExecuting: $full_command\n"
sudo $python_path -m pymobiledevice3 developer dvt simulate-location set --rsd $rsd_data -- $location &
SIM_PID=$!
# Step 5 - Clear the simulated location
echo -e "\n"
yellow_echo -n "Press Enter to clear the simulated location..."
read
echo -e "\nClearing simulated location..."
kill -s SIGINT ${SIM_PID}
sudo $python_path -m pymobiledevice3 developer dvt simulate-location clear --rsd $rsd_data
echo -e "Location cleared!"

# Cleanup: remove the temporary file
echo -e "\nCleaning up temp file"
rm -f "${FUEL_TEMP_FILE}"
echo -e "\nScript complete - Hope you enjoyed!"
