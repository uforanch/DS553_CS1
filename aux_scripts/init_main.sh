#! /bin/bash

if ssh -i ${KEY_PATH}student-admin_key -p "${PORT}" -o StrictHostKeyChecking=no -o BatchMode=yes \
       -o ConnectTimeout=5 student-admin@${MACHINE} "exit" 2>/dev/null; then
  bash lockdown.sh
else
scp -i ${KEY_PATH}mykey -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/ \
    && echo "authorized_keys copied to runner (mykey)" \
    || { echo "lockdown scp FAILED"; exit 1; }
fi
bash deploy.sh