#!/bin/bash
# TO BE EXECUTED LOCALLY

date
set -x

# Update msgpush code
for instance in ${INSTANCES};
do
    ssh -i ${SSH_KEY_PATH} ${SSH_KEY_USER}@${instance} "cd garbage-generator && git pull"
done 


# Copy necessary files (via ssh)
scp -i ${SSH_KEY_PATH} nginx.nogci.conf ${SSH_KEY_USER}@${LB}:~/
scp -i ${SSH_KEY_PATH} nginx.gci.conf ${SSH_KEY_USER}@${LB}:~/