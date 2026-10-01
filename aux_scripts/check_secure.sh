#! /bin/bash

source $HOME/config.env

# cron runs from $HOME, so move to this script's directory before calling other scripts
cd "$PROJECT_PATH" || exit 1

[ -f "${KEY_PATH}agent.env" ] && source "${KEY_PATH}agent.env"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

local_hash=$(git rev-parse HEAD)

#here's where claude helped
repo_hash=$(git ls-remote origin HEAD | awk '{print $1}')
# or:

curl -s -m 5 -o /dev/null http://paffenroth-23.dyn.wpi.edu:8002;
status=$?

if ssh -i ${KEY_PATH}student-admin_key -p "${PORT}" -o StrictHostKeyChecking=no -o BatchMode=yes \
       -o ConnectTimeout=5 student-admin@${MACHINE} "exit" 2>/dev/null; then
    echo "($TIMESTAMP) Computer reset, attempting lockdown and redeploy" >> "redeploy"
    crontab -r
    bash init_main.sh >> "redeploy" 2>&1
    sleep 5m
    bash set_cronjobs.sh
    # put deployment scripts here
elif [ "${status}" -ne 0 ]; then
    echo "($TIMESTAMP) Process stopped" >> "redeploy"
    crontab -r
    bash init_main.sh >> "redeploy" 2>&1
    sleep 5m
    bash set_cronjobs.sh
elif  [ -n "$repo_hash" ] && [ "$local_hash" != "$repo_hash" ]; then
    git pull  >> "redeploy" 2>&1
    echo "($TIMESTAMP) commit detect" >> "redeploy"
    crontab -r
    bash init_main.sh >> "redeploy" 2>&1
    sleep 5m
    bash set_cronjobs.sh
else
    echo "no problems detected ($TIMESTAMP)" > "running_cs.txt"
fi
