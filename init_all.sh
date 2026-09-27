#! /bin/bash

#idea is to put JUST this script on the monitor and then run it to set
#EVERYTHING ELSE

#lines to install cron - later

#gaurdrail to keep it from running twice - later
rm -rf DSCS553

# git clone and change to folder, set aux scripts folder to an env var
git clone https://github.com/uforanch/DS553_CS1.git DSCS553
cd DSCS553/aux_scripts || exit

cp config.env $HOME/config.env
source $HOME/config.env


export PROJECT_PATH=$(pwd)
echo "PROJECT_PATH=$(pwd)">>$HOME/config.env


#generate key add to authorized keys
#Got help from claude on this - `eval "(ssh-agent -s)"` sets variables so processes can find daemon, so "source" is necessary here
source key_setup.sh

bash init_main.sh
#bash set_cronjobs.sh
bash connect_mykey.sh