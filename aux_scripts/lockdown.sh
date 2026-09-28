#! /bin/bash

source $HOME/config.env

#assuming student-admin_key is in key path
cd "$KEY_PATH" || exit
scp -i ${KEY_PATH}student-admin_key -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/ \
    && echo "authorized_keys copied to runner" \
    || { echo "lockdown scp FAILED"; exit 1; }
cd "$PROJECT_PATH" || exit

