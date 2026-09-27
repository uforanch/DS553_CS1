#! /bin/bash

#assuming student-admin_key is in key path
cd "$KEY_PATH" || exit
scp -i student-admin_key -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/
echo "authorized_keys copied to runner"
cd "$PROJECT_PATH" || exit

