#!/bin/bash

date
set -x

# See configrc for experiment configuration.

# GCI on/off switcher.
if [ "$DISABLE_GCI" == "true" ];
then
	FILE_NAME_SUFFIX="nogci"
else
	USE_GCI="true"
	FILE_NAME_SUFFIX="gci"
fi

# Experiment configuration
echo "ROUND_START: ${ROUND_START:=1}"
echo "ROUND_END: ${ROUND_END:=1}"
echo "DISABLE_GCI: ${DISABLE_GCI}"
echo "EXPERIMENT_DURATION: ${EXPERIMENT_DURATION:=120s}"
echo "FILE_NAME_SUFFIX: ${FILE_NAME_SUFFIX}"
echo "LOAD_CLIENT: ${LOAD_CLIENT:=hey}"
echo "INSTANCES: ${INSTANCES:=}"
echo "OUTPUT_DIR: ${OUTPUT_DIR:=/tmp/instances}"
mkdir -p "$OUTPUT_DIR"

for round in `seq ${ROUND_START} ${ROUND_END}`
do
	echo ""
	date
	echo ""
	echo "round ${round}: Bringing up server instances..."

	for port in ${INSTANCE_PORTS};
	do
		ssh ${LB_MASTER} -p ${port} "sudo killall gci-proxy 2>/dev/null; sudo killall dotnet 2>/dev/null; 2>/dev/null; killall mon.sh 2>/dev/null; sleep 5; sudo TO_POWER_OF=${TO_POWER_OF} nohup dotnet run --project ./garbage-generator/GarbageGenerator>msgpush.out 2>msgpush.err --urls=http://*:8080 & sleep 3; sudo nohup ./gci-proxy/gci-proxy -ygen ${YOUNG_GEN} -port 80 -target=localhost:8080 -gci_target=localhost:8080 -gci_path=__gci -disable_gci=${DISABLE_GCI}> proxy.out 2>proxy.err & nohup ./mon.sh >cpu.csv 2>/dev/null &"
	done 

	if [ "$DISABLE_GCI" == "true" ]; 
	then
		ssh ${LB_MASTER} -p ${GCI_NGINX_PORT} "sudo cp nginx.nogci.conf /etc/nginx/nginx.conf"
	else
		ssh ${LB_MASTER} -p ${GCI_NGINX_PORT} "sudo cp nginx.gci.conf /etc/nginx/nginx.conf"
	fi

	sleep 5
	echo "round ${round}: Done. Starting load test..."
	ssh ${LB_MASTER} -p ${GCI_NGINX_PORT} "source ~/.profile; killall vegeta >/dev/null 2>&1; sudo rm /var/log/nginx/*.log; killall vegeta >/dev/null 2>&1; sudo systemctl restart nginx; ${LOAD_CLIENT} >~/client_${FILE_NAME_SUFFIX}_${round}.out 2>~/client_${FILE_NAME_SUFFIX}_${round}.err; cp /var/log/nginx/access.log ~/al_${FILE_NAME_SUFFIX}_${round}.log; cp /var/log/nginx/error.log ~/nginx_error_${FILE_NAME_SUFFIX}_${round}.log"

	i=0
	for port in ${INSTANCE_PORTS};
	do
		ssh ${LB_MASTER} -p ${port} "sudo killall gci-proxy 2>/dev/null; sudo killall dotnet 2>/dev/null; killall mon.sh 2>/dev/null; mv cpu.csv cpu_${FILE_NAME_SUFFIX}_${i}_${round}.csv; mv proxy.out proxy_${FILE_NAME_SUFFIX}_${i}_${round}.out; mv msgpush.out msgpush_${FILE_NAME_SUFFIX}_${i}_${round}.out; mv msgpush.err msgpush_${FILE_NAME_SUFFIX}_${i}_${round}.err"
		((i++))
	done

	echo "round ${round}: Done. Copying results and cleaning up instances..."
	scp -P ${GCI_NGINX_PORT} ${LB_MASTER}:~/\{*.log,*.out,*.err\} ${OUTPUT_DIR}
	ssh ${LB_MASTER} -p ${GCI_NGINX_PORT} "rm *.log; rm *.out *.err"
	sed -i '1i timestamp;status;request_time;upstream_response_time' ${OUTPUT_DIR}/al_${FILE_NAME_SUFFIX}_${round}.log

	i=0
	for port in ${INSTANCE_PORTS};
	do
		scp -P ${port} ${LB_MASTER}:~/\{cpu*.csv,proxy*.out,proxy*.err,msgpush*.out,msgpush*.err\} ${OUTPUT_DIR}
		ssh ${LB_MASTER} -p ${port} "rm cpu*.csv *.out *.err"
		((i++))
	done
	echo "round ${round}: Finished."
	echo ""
	date
	sleep 5s
done
