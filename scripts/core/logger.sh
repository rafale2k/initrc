#!/bin/bash
# shellcheck disable=SC2148

log_info()    { echo -e "\e[34m[INFO]\e[0m $1"; }
log_success() { echo -e "\e[32m[OK]\e[0m   $1"; }
log_warn()    { echo -e "\e[33m[WARN]\e[0m $1"; }
log_error()   { echo -e "\e[31m[FAIL]\e[0m $1" >&2; exit 1; }
