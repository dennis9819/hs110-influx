# Simple script to sotre HS110 Power-Data metrics to influx
=> New Python version: https://github.com/dennis9819/hs110-influx-2

This script uses the tplink-smartplug python library to retrieve power data form the TP-Link HS110 Smart-Plug and store it into an influx-database.
https://github.com/softScheck/tplink-smartplug

## Setup
### Clone the this project to your computer:
```
mkdir /opt/hs110
cd /opt/hs110
git clone 
```
### Clone the tplink smartplug library to your computer:
```
git clone https://github.com/softScheck/tplink-smartplug.git
```
### Create configuration
```
cd hs110-influx
cp gather.sample.env gather.env
vim gather.env
```
Edit your configurtaion file. Enter your Influx-IP, database and credentials as well as the hs110's IP-Adress.
Change the `TPLINK_DIR` to `/opt/hs110/tplink-smartplug`

Your configfile should look something like this:
```
TPLINK_DIR=/opt/hs110/tplink-smartplug
TPLINK_IP=10.110.0.161
DB_USER=admin
DB_PASSWD=password
DB_IP=127.0.0.1:8086
DB_DB=metrics
```

### Create cronjobs
If you execute `./gather.sh`, the script will gather the data and insert it into the database.
To automate this, one option is to use cronjobs.

Open your crontab file in an editor:
```
crontab -e
```

Insert the following lines at the bottom:
```
* * * * * /bin/bash /opt/hs110/hs110-influx/gather.sh >/dev/null 2>&1
* * * * * sleep 30; /bin/bash /opt/hs110/hs110-influx/gather.sh >/dev/null 2>&1
```

This will execute the schript every 30 seconds. You can also change the intervall. For more information on how to adjust cronjobs use `man crontab`

## Configuration
Parameters are configured in the gather.env file

TPLINK_DIR -> directory to tplink-smartplug python library
TPLINK_IP -> HS110 IP-Adress

DB_USER -> InfluxDB Username
DB_PASSWD -> InfluxDB Password
DB_IP -> InfluxDB IP and Port (<ip>:<port>)
DB_DB -> InfluxDB Database


Crontab entries for 30s intervall
```
* * * * * /bin/bash /home/dgadmin/tplink-smartplug/readPower.sh >/dev/null 2>&1
* * * * * sleep 30; /bin/bash /home/dgadmin/tplink-smartplug/readPower.sh >/dev/null 2>&1
```
