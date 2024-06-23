#!/bin/bash

yellow_echo () {
  echo -ne "\033[33m"
  echo -e "$@\033[0m"
}

red_echo() {
  echo -ne "\033[31m"
  echo -e "$@\033[0m"
}

blue_echo (){
  echo -ne "\033[34m"
  echo -e "$@\033[0m"
}

magenta_echo (){
  echo -ne "\033[35m"
  echo -e "$@\033[0m"
}

cyan_echo (){
  echo -ne "\033[36m"
  echo -e "$@\033[0m"
}
