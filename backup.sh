#!/bin/bash
set -u
. ./.passphrase
#### Exit if .passphrase is not configured ###
if [[ $DB_PASSWORD = "MY_SQL_ADMIN_PASSWORD" ]] ; then
    echo "[Error] Please Modify .passphrase with your own values"
    exit 
fi
##### setting up your backup folders
Main_Dir=/backups
Full_Backup_Dir=/gpg-full
Full_Dir=${Full_Backup_Dir}
Mysql_Dir=/mysql
Main_DB_Dir=/backups
Full_DB_Dir=/gpg-full
Mysql_DB_Dir=/mysql
Full_Backup_Count=10
DB_Backup_Count=30
Dropbox_Uploader=/opt/Dropbox-Uploader
########## Ensuring Backup Local folders exist #################3
if [[ ! -d ${Main_Dir}${Full_Dir} ]] ; then 
    echo "${Main_Dir}${Full_Dir} not found"
    exit
fi
if [[ ! -d ${Main_Dir}${Mysql_Dir} ]] ; then
    echo "${Main_Dir}${Mysql_Dir} not found "
    exit
fi
###############################################################################
######## Creating DropBox Directories if it doesn't exist###################### 
${Dropbox_Uploader}/dropbox_uploader.sh mkdir ${Main_DB_Dir}${Full_DB_Dir}
${Dropbox_Uploader}/dropbox_uploader.sh mkdir ${Main_DB_Dir}${Mysql_DB_Dir}

###############################################################################
######## Creating full mysql backup ###########################################
mysqldump --all-databases > ${Main_Dir}${Mysql_Dir}/dump-$( date '+%Y-%m-%d_%H-%M-%S' ).sql -u root -p${DB_PASSWORD}

#### delete local backups if exceed DB_Backup_Count
while [[ $(ls -1 ${Main_Dir}${Mysql_Dir} | wc -l ) -gt ${DB_Backup_Count} ]]; do
    rm -rf ${Main_Dir}${Mysql_Dir}/$(ls -1 ${Main_Dir}${Mysql_Dir} | head -1 )
done
#### upload current backups to DropBox
${Dropbox_Uploader}/dropbox_uploader.sh -s upload  ${Main_Dir}${Mysql_Dir}/* ${Main_DB_Dir}${Mysql_DB_Dir}

###############################################################################
######## Creating full filesystem gpg backup ##################################
duplicity --encrypt-key ${Gpg_Key} --exclude /bin --exclude /boot --exclude /dev --exclude /lib --exclude /lib64 --exclude /media --exclude /mnt --exclude /proc --exclude /run --exclude /sbin --exclude /srv --exclude /sys --exclude /tmp --exclude /usr --exclude ${Main_Dir} / file://${Main_Dir}${Full_Dir}
tar -rvf ${Main_Dir}${Full_Dir}/full_$(date '+%Y-%m-%d_%H-%M-%S').tar ${Main_Dir}${Full_Dir}/duplicity*
rm -rf ${Main_Dir}${Full_Dir}/duplicity*

#### delete local backups if exceed Backup_Count
while [[ $(ls -1 ${Main_Dir}${Full_Dir} | wc -l ) -gt ${Full_Backup_Count} ]]; do
    rm -rf ${Main_Dir}${Full_Dir}/$(ls -1 ${Main_Dir}${Full_Dir} | head -1 )
done

#### upload current backups to DropBox
${Dropbox_Uploader}/dropbox_uploader.sh -s upload  ${Main_Dir}${Full_Dir}/* ${Main_Dir}${Full_DB_Dir}

###############################################################################
######### Delete Oldest mysql backup if backup count is more than 30 backups### 
while [[ $(${Dropbox_Uploader}/dropbox_uploader.sh list ${Main_DB_Dir}${Mysql_DB_Dir} | grep dump* |cut -d " " -f4 | wc -l) -gt ${DB_Backup_Count}  ]]; do
    echo "there is more than ${DB_Backup_Count} mysql backups"
    echo "delete Oldest backup"
    ${Dropbox_Uploader}/dropbox_uploader.sh delete ${Main_DB_Dir}${Mysql_DB_Dir}/$(${Dropbox_Uploader}/dropbox_uploader.sh list ${Main_DB_Dir}${Mysql_DB_Dir} | grep dump* |cut -d " " -f4 | head -1)
done
###############################################################################
########## Delete Oldest full  bakcup if full backup count is more than 15 #### 
while [[ $(${Dropbox_Uploader}/dropbox_uploader.sh list ${Main_DB_Dir}${Full_DB_Dir} | grep full_.*tar |cut -d " " -f4 | wc -l) -gt ${Full_Backup_Count} ]]; do
    echo "there is more than ${Full_Backup_Count} backups"
    echo "delete Oldest backup"
    ${Dropbox_Uploader}/dropbox_uploader.sh delete ${Main_DB_Dir}${Full_DB_Dir}/$(${Dropbox_Uploader}/dropbox_uploader.sh list ${Main_DB_Dir}${Full_DB_Dir} | grep full_.*tar |cut -d " " -f4 | head -1)
done
