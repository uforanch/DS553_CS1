#! /bin/bash

source $HOME/config.env

[ -f "${KEY_PATH}agent.env" ] && source "${KEY_PATH}agent.env"


JOB="* * * * * bash $(pwd)/check_secure.sh"
(crontab -l 2>/dev/null | grep -Fv "$(pwd)/check_secure.sh"; echo "$JOB") | crontab -
echo "crontabs monitor"
crontab -l
