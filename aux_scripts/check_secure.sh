#! /bin/bash

[ -f "${KEY_PATH}agent.env" ] && source "${KEY_PATH}agent.env"


if ssh -i student-admin_key -p "${PORT}" -o StrictHostKeyChecking=no -o BatchMode=yes \
       -o ConnectTimeout=5 student-admin@${MACHINE} "exit" 2>/dev/null; then
    echo "Computer reset, attempting lockdown and redeploy"
    bash init_main.sh
    # put deployment scripts here
else
    echo "no studen-admin account"
fi