#! /bin/bash

source $HOME/config.env

ssh -i ${KEY_PATH}mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}