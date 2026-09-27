#! /bin/bash

source $HOME/config.env

# generate a key, add to authorized keys
cd "$KEY_PATH" || { echo "Authorized key path DNE"; exit 1; }

if [ ! -f mykey ]; then
    ssh-keygen -f mykey -t ed25519 -N ""
    cat mykey.pub >> authorized_keys
fi

echo "mykey generated"

cat mykey.pub >> authorized_keys

echo "mykey added to authorized_keys"

# Add the key to the ssh-agent
eval "$(ssh-agent -s)"
#claude recced line for check_secure, which can't access ssh-agent otherwise
env | grep -E '^SSH_AUTH_SOCK=|^SSH_AGENT_PID=' > "${KEY_PATH}agent.env"

ssh-add mykey
ssh-add student-admin_key

echo "mykey added to agent"

cd $PROJECT_PATH || exit

