#!/bin/bash

export WAIT_API_REFRESH=300
export API_URL="https://projectzerothree.info/api.php?format=json"
export FUEL_TYPES=("E10" "U91" "U95" "U98" "Diesel" "LPG")
export REGIONS=('VIC' 'NSW' 'QLD' 'WA')

update_api_data() {
  local request req_time err
  if test -z "${API_DATA}" ||
    test $((${curr_time} - ${API_REQUEST_TIME})) -gt 0${WAIT_API_REFRESH}; then
      request=$(curl -sS --location "$API_URL")
      err=$?
      test $err -gt 0 &&
        >&2 echo "Failed to update fuel api data" &&
        return $err
    req_time=$(echo "${request}" | jq -r '.updated')
      err=$?
      test $err -gt 0 &&
        >&2 echo "Error in updated fuel api data" && 
        return $err
    export API_DATA="${request}"
    export API_REQUEST_TIME="${req_time}"
  fi
  test -z "${API_DATA}" && err=$? &&
    >&2 echo "No API data recorded" && return $err
  true
}

# Function to make API request and extract data based on user choice
get_api_data() {
    local fuel=$1
    local state=$2
    local curr_time=$(date +%s)

    update_api_data || return $?
    
    # Extract data based on user choice
    local selected_data=$(echo "${API_DATA}" | jq -r '.regions[] | select(.region == "'"$state"'").prices[] | select(.type == "'"$fuel"'")') || return $?

    # Extract relevant information
    local type=$(echo $selected_data | jq -r '.type')
    local price=$(echo $selected_data | jq -r '.price')
    local suburb=$(echo $selected_data | jq -r '.suburb')
    local state=$(echo $selected_data | jq -r '.state')
    local lat=$(echo $selected_data | jq -r '.lat')
    local lng=$(echo $selected_data | jq -r '.lng')
    
    # Print selected data
    echo -e "\nYou selected: $fuel\n"
    echo -e "The cheapest $fuel is at $suburb in $state\n"
    echo -e "\nType: $type\nPrice: $price\nlat: $lat\nlng: $lng"
    echo -e "\n"
    
    # Set the location variable
    location="$lat $lng"
}
