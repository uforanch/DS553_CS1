#! /bin/bash

#assuming student-admin_key is in key path
cd "$KEY_PATH"
scp -i student-admin_key -P ${PORT} -o StrictHostKeyChecking=no authorized_keys student-admin@${MACHINE}:~/.ssh/
cd "$PROJECT_PATH"

