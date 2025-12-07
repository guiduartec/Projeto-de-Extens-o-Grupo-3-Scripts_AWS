#!/bin/bash
set -e
sudo yum install cronie -y
sudo systemctl enable crond
sudo systemctl start crond

sudo yum -y install python3 python3-pip
pip install requests
pip install python-dotenv

USUARIO="ec2-user"
ARQUIVO_SCRIPT="/home/$USUARIO/create_backup.sh"
ARQUIVO_LOG="/var/log/backup_diario_cron.log"

sudo touch $ARQUIVO_LOG
sudo chown $USUARIO:$USUARIO $ARQUIVO_LOG

CRON_JOB="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
55 13 * * * $ARQUIVO_SCRIPT > $ARQUIVO_LOG 2>&1"

echo "$CRON_JOB"
sudo bash -c "(crontab -l -u $USUARIO 2>/dev/null; echo \"$CRON_JOB\") | crontab -u $USUARIO -"