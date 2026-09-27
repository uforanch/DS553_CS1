#! /bin/bash

#idea is to put JUST this script on the monitor and then run it to set
#EVERYTHING ELSE

#set the environment variables on monitor for all other monitor run scripts
#SETUP:
#have student key AND authorized keys list of outside keys in key path

set -a
PORT=22002
MACHINE=paffenroth-23.dyn.wpi.edu
KEY_PATH=$HOME/keys/
set +a

#lines to install cron - later

#gaurdrail to keep it from running twice - later
rm -rf DSCS553

# git clone and change to folder, set aux scripts folder to an env var
git clone https://github.com/uforanch/DS553_CS1.git DSCS553
cd DSCS553/aux_scripts || exit

export PROJECT_PATH=$(pwd)


#generate key add to authorized keys
#Got help from claude on this - `eval "(ssh-agent -s)"` sets variables so processes can find daemon, so "source" is necessary here
source key_setup.sh

bash init_main.sh
bash set_cronjobs.sh