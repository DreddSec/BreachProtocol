#!/bin/bash

# Colors
red() { echo -e "\e[31m$1\e[0m"; }
green() { echo -e "\e[32m$1\e[0m"; }
blue() { echo -e "\e[34m$1\e[0m"; }
yellow() { echo -e "\e[33m$1\e[0m"; }
orange() { echo -e "\e[38;5;208m$1\e[0m"; }


# BANNER WITH figlet
banner() {
    echo -e "\n$(figlet -c 6 -f 2 -s 0.5 -w 80 BreachProtocol)"
    echo -e "\n$(figlet -c 6 -f 2 -s 0.5 -w 80 v2.0)"
    echo -e "\n$(figlet -c 6 -f 2 -s 0.5 -w 80 by DreddSec)\n"
}


DATA_PATH="/${HOME}/.data/"