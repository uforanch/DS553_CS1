#! /bin/bash

source $HOME/config.env

# see deploy_second_part.sh

# install basics such as python and uv on runner
# install cron on runner (init_all runs on monitor)
# copy
#
# no cron jobs as this will be reun

cd "$PROJECT_PATH/../.."
echo $(pwd)

COMMAND="ssh -i ${KEY_PATH}mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

${COMMAND} rm -r /DSCS553
scp -i ${KEY_PATH}mykey -P ${PORT} -o StrictHostKeyChecking=no -r DSCS553 student-admin@${MACHINE}:~/

${COMMAND} "sudo apt install -qq -y python3-venv"
${COMMAND} "curl -LsSf https://astral.sh/uv/install.sh | sh"

${COMMAND} "cd DSCS553 && \$HOME/.local/bin/uv venv && \$HOME/.local/bin/uv pip install -r requirements_local.txt"
${COMMAND} "nohup DSCS553/.venv/bin/python3 DSCS553/app.py > log.txt 2>&1 &"

