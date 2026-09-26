#! /bin/bash

ssh -i student_admin_key -p ${PORT} -o StrictHostKeyChecking=no student-admin@${MACHINE}