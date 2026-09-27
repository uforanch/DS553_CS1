#! /bin/bash

source $HOME/config.env

# see deploy_second_part.sh

# install basics such as python and uv on runner
# install cron on runner (init_all runs on monitor)
# copy
#
# no cron jobs as this will be reun

COMMAND="ssh -i mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}"

scp -P ${PORT} -o StrictHostKeyChecking=no -r DSCS553 student-admin@${MACHINE}:~/

${COMMAND} "ls DSCS553"
${COMMAND} "cd DSCS553 && echo \"export PROJECT_PATH=\$(pwd)\" >> ~/.bashrc"

${COMMAND} "sudo apt install -qq -y python3-venv"
${COMMAND} "curl -LsSf https://astral.sh/uv/install.sh | sh"
#${COMMAND} "cd DSCS553_example_uv && uv venv"
${COMMAND} "cd DSCS553_example_uv && \$HOME/.local/bin/uv venv && \$HOME/.local/bin/uv pip install -r requirements_local.txt"
#${COMMAND} "cd DSCS553_example_uv && source .venv/bin/activate && uv pip install -r requirements_local.txt"
${COMMAND} "nohup DSCS553_example_uv/.venv/bin/python3 DSCS553_example/app.py > log.txt 2>&1 &"
