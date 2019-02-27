#!/bin/bash

SCRIPT_DIR="/var/opt/tableau/tableau_server/data/scripts"
SCRIPT_NAME="tableau-server-housekeeping-linux.sh"
TSMAGENT=$USER
TSMAGENT_HOME="/home/$TSMAGENT"
# Run once a day at 01:00
SCRIPT_CRON="0 1 * * * ${SCRIPT_DIR}/${SCRIPT_NAME} > /home/${TSMAGENT}/${SCRIPT_NAME}.log"

echo "Create a new directory called scripts in your Tableau server data directory"
mkdir -p $SCRIPT_DIR

echo "Copy script file"
cp $SCRIPT_NAME $SCRIPT_DIR

echo "Change permisions of this directory and script"
sudo chown -R $TSMAGENT:tableau $SCRIPT_DIR
sudo chmod +x $SCRIPT_DIR/$SCRIPT_NAME
sudo usermod -G tableau -a $TSMAGENT

# Execute the script as the tsm admin user to test it works correctly in your environment…
# sudo su $tsmuser -c $SCRIPT_DIR/$SCRIPT_NAME

echo "Schedule script using cron"
sudo su $TSMAGENT -c "crontab -l > $TSMAGENT_HOME/crontab.txt"
if grep -Fxq "${SCRIPT_CRON}" crontab.txt; then
    echo "Script already in cron"
    echo "modify manually"
else
    echo "Add script in cron"
    echo "${SCRIPT_CRON}" | sudo tee -a $TSMAGENT_HOME/crontab.txt
    sudo su - $TSMAGENT -c 'cat crontab.txt |  crontab'
fi
