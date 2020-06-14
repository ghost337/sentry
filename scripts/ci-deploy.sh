#!/usr/bin/env bash
# exit script when any command ran here returns with non-zero exit code
set -e

envsubst <./docker-compose.yml >./docker-compose.yml.out
mv ./docker-compose.yml.out ./docker-compose.yml

# First check if dir still exists, if no - create them
ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -p${SSH_PORT} ${USER}@${INSTANCE} '[ -d ~/projects ] || mkdir -p ~/projects'

# Push docker-compose.yml file to host
scp -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -P${SSH_PORT} docker-compose.yml ${USER}@${INSTANCE}:~/projects/

# Run pulling the new images on the host
ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -p${SSH_PORT} ${USER}@${INSTANCE} 'docker-compose -f ~/projects/docker-compose.yml pull'

# Run DB migrations from tmp docker container
ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -p${SSH_PORT} ${USER}@${INSTANCE} 'docker-compose -f ~/projects/docker-compose.yml run --rm web upgrade --noinput'

# Run new version of application
ssh -o "StrictHostKeyChecking no" -o "UserKnownHostsFile=/dev/null" -p${SSH_PORT} ${USER}@${INSTANCE} 'docker-compose -f ~/projects/docker-compose.yml up -d --no-build'
