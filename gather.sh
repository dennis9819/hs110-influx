#!/bin/bash
#
# ==> Get data from plug

if [ -f gather.env ]; then
    # Load Environment Variables
    export $(cat gather.env | grep -v '#' | awk '/=/ {print $1}')
fi

touch "./last_mac.tmp"
touch "./last_alias.tmp"

# CHECK IF REACHABLE
PING_RES=$(fping -c1 -t500 ${TPLINK_IP} 2>&1 | grep bytes | wc -l)
TIMESTAMP=$(date +%s%N)
if [[ ($PING_RES -eq 0) ]]
then
        #Write last Device details and zero metrics
        echo "Plug not reachable."
        DEV_STATE=-1
        DEV_MAC=$(cat ./last_mac.tmp)
        DEV_ALIAS=$(cat ./last_alias.tmp)
        READ_VOLATGE=0
        READ_AMPS=0
        READ_WATT=0
        READ_WATTHOURS=0
else
        #get current stats
        echo "=> GET DATA FROM PLUG @ ${TPLINK_IP}"
        #READ DEVICE INFO
        READINFO=$(${TPLINK_DIR}/tplink_smartplug.py -t ${TPLINK_IP} -c info)
        DEV_MAC=$(echo ${READINFO} | sed -e 's/^.*mac\"://;s/,.*$//')
        DEV_STATE=$(echo ${READINFO} | sed -e 's/^.*relay_state\"://;s/,.*$//')
        DEV_ALIAS=$(echo ${READINFO} | sed -e 's/^.*alias\"://;s/,.*$//;s/\s/_/gm')
        # READ METRICS
        READOUT=$(${TPLINK_DIR}/tplink_smartplug.py -t ${TPLINK_IP} -c energy)
        READ_VOLATGE=$(echo ${READOUT} | sed -e 's/^.*mv\"://;s/,.*$//')
        READ_AMPS=$(echo ${READOUT} | sed -e 's/^.*ma\"://;s/,.*$//')
        READ_WATT=$(echo ${READOUT} | sed -e 's/^.*mw\"://;s/,.*$//')
        READ_WATTHOURS=$(echo ${READOUT} | sed -e 's/^.*wh\"://;s/,.*$//')

        #store values
        echo "${DEV_MAC}" > ./last_mac.tmp
        echo "${DEV_ALIAS}" > ./last_alias.tmp

fi

#echo "VOLTAGE: $READ_VOLATGE"
#echo "AMPS   : $READ_AMPS"
#echo "WATTS  : $READ_WATT"
#echo "WATTHRS: $READ_WATTHOURS"
#echo ""
#echo "MAC    : $DEV_MAC"
#echo "STATE  : $DEV_STATE"
#echo "ALIAS  : $DEV_ALIAS"

# ==> Store data to InfluxDB
DATA_LINE="power_plug,mac=${DEV_MAC},alias=${DEV_ALIAS},ip=$(echo $TPLINK_IP | sed 's/\./-/gm') volts=${READ_VOLATGE},amps=${READ_AMPS},watts=${READ_WATT},wh=${READ_WATTHOURS} $TIMESTAMP"
DATA_ESCAPED="$(echo "$DATA_LINE" | sed 's/\"//gm;s/\:/-/gm')"
URL="http://${DB_IP}/write?db=${DB_DB}"

echo "$DATA_ESCAPED"

curl -i -XPOST "${URL}" \
        --header "Authorization: Token ${DB_USER}:${DB_PASSWD}" \
        --data-binary "$DATA_ESCAPED"