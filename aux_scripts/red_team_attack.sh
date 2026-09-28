#!/bin/bash

# vars
PORT=22000
MACHINE=paffenroth-23.dyn.wpi.edu
KEY=student-admin_key

FILE="ports.txt"
num_files=$(wc -l < $FILE)

# Loop to create files
for i in $(seq 1 $num_files); do
  OTHER_PORT=$(sed -n "${i}p" $FILE)
  GROUP=$((OTHER_PORT%1000))
  echo "trying group ${GROUP} at port $((${OTHER_PORT})) "
  echo "------------------------------------------------"
  echo "------------------------------------------------"
  if ssh -i $KEY -p $((${OTHER_PORT})) -o StrictHostKeyChecking=no student-admin@${MACHINE} hostname; then
    echo "group ${GROUP} is vulnerable!"
  else
    echo "group ${GROUP} is protected!"
  fi
  echo "------------------------------------------------"
  echo "------------------------------------------------"
  sleep $((RANDOM % 5))
done