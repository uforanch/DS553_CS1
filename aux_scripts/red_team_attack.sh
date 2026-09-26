#!/bin/bash


#TODO test this with just a file and an echo line.
#TODO make this do something different on finding vulnerable computer

# Number possible groups
num_files=21

# vars
PORT=22000
MACHINE=paffenroth-23.dyn.wpi.edu
KEY=$HOME/projects/1_classes/DS553_private/scripts/CS2/student-admin_key

FILE="ports.txt"

# Loop to create files
for i in $(seq 1 $num_files); do
  OTHER_PORT=$(sed -n "${i}p $FILE")
  echo "trying group ${i} at port $((${OTHER_PORT})) "
  echo "------------------------------------------------"
  echo "------------------------------------------------"
  if ssh -i $KEY -p $((${OTHER_PORT})) -o StrictHostKeyChecking=no student-admin@${MACHINE} hostname; then
    echo "group ${i} is vulnerable!"
  else
    echo "group ${i} is protected!"
  fi
  echo "------------------------------------------------"
  echo "------------------------------------------------"
  sleep $((RANDOM % 30))
done