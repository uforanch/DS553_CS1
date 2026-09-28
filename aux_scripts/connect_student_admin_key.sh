#! /bin/bash

source $HOME/config.env

ssh -i ${KEY_PATH}student-admin_key -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}