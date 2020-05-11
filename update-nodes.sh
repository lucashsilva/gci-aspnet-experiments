#!/bin/bash
# TO BE EXECUTED LOCALLY

date
set -x

# Update msgpush code
for port in ${INSTANCE_PORTS};
do
    ssh -p ${port} ${LB_MASTER} "cd garbage-generator && git pull"
    scp -P ${port} mon.sh ${LB_MASTER}:~/
    ssh -p ${port} ${LB_MASTER} "chmod a+x mon.sh"
done 


# Copy necessary files (via ssh)
scp -P ${GCI_NGINX_PORT} nginx.nogci.conf ${LB_MASTER}:~/
scp -P ${GCI_NGINX_PORT} nginx.gci.conf ${LB_MASTER}:~/
