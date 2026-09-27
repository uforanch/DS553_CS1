#! /bin/bash

JOB="* * * * * $(pwd)/check_secure.sh"
(crontab -l 2>/dev/null | grep -Fv "$(pwd)/check_secure.sh"; echo "$JOB") | crontab -

COMMAND="ssh -i mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

JOB="* * * * * $PROJECT_PATH/check_git_pull.sh"
${COMMAND} "(crontab -l 2>/dev/null | grep -Fv \"$PROJECT_PATH/check_git_pull.sh\"; echo \"$JOB\") | crontab -"