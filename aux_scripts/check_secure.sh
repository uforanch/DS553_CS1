#! /bin/bash

source $HOME/config.env

[ -f "${KEY_PATH}agent.env" ] && source "${KEY_PATH}agent.env"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")


if ssh -i ${KEY_PATH}student-admin_key -p "${PORT}" -o StrictHostKeyChecking=no -o BatchMode=yes \
       -o ConnectTimeout=5 student-admin@${MACHINE} "exit" 2>/dev/null; then
    echo "($TIMESTAMP) Computer reset, attempting lockdown and redeploy" >> "redeploy"
    bash init_main.sh >> "redeploy"
    # put deployment scripts here
else
    echo "no student-admin account ($TIMESTAMP)" > "running_cs.txt"
fi