#!/bin/bash

date
set -x

# See configrc for experiment configuration.

# GCI on/off switcher.
if [ "$DISABLE_GCI" == "true" ];
then
	FILE_NAME_SUFFIX="nogci"
	SERVER_PORT=3000
else
	USE_GCI="true"
	FILE_NAME_SUFFIX="gci"
	SERVER_PORT=8080
fi

# Experiment configuration
echo "ROUND_START: ${ROUND_START:=1}"
echo "ROUND_END: ${ROUND_END:=1}"
echo "DISABLE_GCI: ${DISABLE_GCI}"
echo "EXPERIMENT_DURATION: ${EXPERIMENT_DURATION:=120s}"
echo "SUFFIX: ${SUFFIX:=}"
echo "THREADS: ${THREADS:=1}"
echo "JVMARGS: ${JVMARGS:=}"
FILE_NAME_SUFFIX="${FILE_NAME_SUFFIX}${SUFFIX}"
echo "LOAD_CLIENT:${LOAD_CLIENT:=hey}"
echo "INSTANCES:${INSTANCES:=}"
echo "SSH_KEY_PATH:${SSH_KEY_PATH}"
echo "SSH_KEY_USER:${SSH_KEY_USER}"

for round in `seq ${ROUND_START} ${ROUND_END}`
	echo ""
	date
	echo ""
	echo "round ${round}: Bringing up server instances..."

	for instance in ${INSTANCES};
	do
		ssh -i ${SSH_KEY_PATH} ${SSH_KEY_USER}@${instance} "sudo killall gci-proxy 2>/dev/null; sudo killall dotnet 2>/dev/null; rm gc.log shed.csv st.csv 2>/dev/null; killall mon.sh 2>/dev/null; sleep 5; sudo nohup dotnet run --project ./garbage-generator/GarbageGenerator>msgpush.out 2>msgpush.err --urls=http://*:8080 & sleep 3; sudo nohup ./gci-proxy/gci-proxy -ygen ${YOUNG_GEN} -port 80 -target=localhost:8080 -gci_target=localhost:8080 -gci_path=__gci -disable_gci=${DISABLE_GCI}> proxy.out 2>proxy.err & nohup ./mon.sh >cpu.csv 2>/dev/null &"
	done 

	if [ "$DISABLE_GCI" == "true" ]; 
	then
		ssh -i ${SSH_KEY_PATH} ${SSH_KEY_USER}@${LB} "sudo cp nginx.nogci.conf /etc/nginx/nginx.conf"
	else
		ssh -i ${SSH_KEY_PATH} ${SSH_KEY_USER}@${LB} "sudo cp nginx.gci.conf /etc/nginx/nginx.conf"
	fi

	sleep 5
	echo "round ${round}: Done. Starting load test..."
	ssh -i ${SSH_KEY_PATH} ${SSH_KEY_USER}@${LB} "source ~/.profile; killall vegeta >/dev/null 2>&1; sudo rm /var/log/nginx/*.log; killall vegeta >/dev/null 2>&1; sudo systemctl restart nginx; ${LOAD_CLIENT} >~/client_${FILE_NAME_SUFFIX}_${round}.out 2>~/client_${FILE_NAME_SUFFIX}_${round}.err; cp /var/log/nginx/access.log ~/al_${FILE_NAME_SUFFIX}_${round}.log; cp /var/log/nginx/error.log ~/nginx_error_${FILE_NAME_SUFFIX}_${round}.log"

	# to do 
	# echo "round ${round}: Done. Putting server instances down..."
done