#! /bin/bash

ssh -i mykey -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}