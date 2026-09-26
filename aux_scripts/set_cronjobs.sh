#! /bin/bash

JOB="*/1 * * * $(pwd)/check_secure.sh"
(crontab -l 2>/dev/null | grep -Fv "$(pwd)/check_secure.sh"; echo "$JOB") | crontab -

COMMAND="ssh -i mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

JOB="*/1 * * * $PROJECT_PATH/check_git_pull.sh"
${COMMAND} "(crontab -l 2>/dev/null | grep -Fv \"$PROJECT_PATH/check_git_pull.sh\"; echo \"$JOB\") | crontab -"