#! /bin/bash

source $HOME/config.env

[ -f "${KEY_PATH}agent.env" ] && source "${KEY_PATH}agent.env"


JOB="* * * * * bash $(pwd)/check_secure.sh"
(crontab -l 2>/dev/null | grep -Fv "$(pwd)/check_secure.sh"; echo "$JOB") | crontab -

COMMAND="ssh -i ${KEY_PATH}mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

JOB="* * * * * bash ~/DSCS553/aux_scripts/check_git_pull.sh"
${COMMAND} "(crontab -l 2>/dev/null | grep -Fv \"~/DSCS553/aux_scripts/check_git_pull.sh\"; echo \"$JOB\") | crontab -"