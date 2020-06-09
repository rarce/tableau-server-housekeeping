#!/bin/bash
#Tableau Server on Linux Housekeeping Script
#Originally created by Jonathan MacDonald @ The Information Lab

# Helper function
timestamp()
{
 date '+%Y-%m-%d %H:%M:%S'
}

#VARIABLES SECTION
# Set some variables - you should change these to match your own environment
DATE=`date +%Y-%m-%d`
# Tableau Server version
VERSION="20202.20.0525.1210"
# Path to TSM executable
TSMPATH="/opt/tableau/tableau_server/packages/customer-bin.$VERSION"
# Export this path to environment variables (for cron to run properly)
PATH=/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin:$TSMPATH
# Who is your TSM administrator user?
# Where is your Tableau Server data directory installed? No need to change if default
DATAPATH="/var/opt/tableau/tableau_server/data"
LOGPATH="$DATAPATH/tabsvc/files/log-archives"
BACKUPPATH="$DATAPATH/tabsvc/files/backups"
BACKUPDAYS="1"
LOGDAYS="1"
CONFIGFILE='/etc/tableau-server-housekeeping.cfg'
# load config
source "$CONFIGFILE"

# configure gsutil
gcloud auth activate-service-account --key-file $SACREDENTIAL

# LOGS SECTION
cd $LOGPATH
echo "$(timestamp): Cleaning up old log files..."
# count the number of log files eligible for deletion and output 
lines=$(find $LOGPATH -type f -name '*.zip' -mtime +$LOGDAYS | wc -l)
if [ $lines -eq 0 ]; then 
	echo "$(timestamp): $lines found, skipping..."
	else "$(timestamp): $lines found, deleting..."
		#remove log archives older than the specified number of days
		find $LOGPATH -type f -name '*.zip' -mtime +$LOGDAYS -exec rm {} \;
		echo "$(timestamp): Cleaning up completed."		
fi


# archive current logs 
echo "$(timestamp): Archiving current logs..."
tsm maintenance ziplogs -a -t -o -f logs-$DATE.zip -u $TSMUSER
#copy logs to different location (optional)
echo "$(timestamp): Copying logs to remote share"
gsutil cp $LOGPATH/logs-$DATE.zip gs://$BUCKET/tableau/logs/logs-$DATE.zip

# END OF LOGS SECTION

# BACKUP SECTION
cd $BACKUPPATH
echo "$(timestamp): Cleaning up old backups..."
# count the number of log files eligible for deletion and output 
lines=$(find $BACKUPPATH -type f -name '*.tsbak' -mtime +$BACKUPDAYS | wc -l)
if [ $lines -eq 0 ]; then 
		echo "$(timestamp): $lines old backups found, skipping..."
	else $(timestamp) $lines old backups found, deleting...
		#remove backup files older than N days
		find $BACKUPPATH -type f -name '*.tsbak' -mtime +$BACKUPDAYS -exec rm {} \;
fi

echo "$(timestamp): Exporting current settings..."
tsm settings export -f $BACKUPPATH/settings.json -u $TSMUSER
echo "$(timestamp): Backup up Tableau Server data..."
tsm maintenance backup -f tableau-backup-$DATE -u $TSMUSER
echo "$(timestamp): Copying backup and settings to remote share"
gsutil cp $BACKUPPATH/tableau-backup-$DATE.tsbak gs://$BUCKET/tableau/backup/tableau-backup-$DATE.tsbak
# END OF BACKUP SECTION

# CLEANUP AND RESTART SECTION
# cleanup old logs and temp files 
echo "$(timestamp): Cleaning up Tableau Server..."
tsm maintenance cleanup -a -u $TSMUSER
# END OF CLEANUP AND RESTART SECTION

# END OF SCRIPT
echo "$(timestamp): Housekeeping completed"