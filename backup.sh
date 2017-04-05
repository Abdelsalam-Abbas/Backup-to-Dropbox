#!/bin/bash
set -u
set -x
. /root/.passphrase
Main_Dir=/backups
Full_Dir=/pgp-full
Mysql_Dir=/mysql
Main_DB_Dir=/backups
Full_DB_Dir=/pgp-full
Mysql_DB_Dir=/mysql
Backup_Count=2
###############################################################################
######## Creating DropBox Directories if it doesn't exist###################### 
/opt/Dropbox-Uploader/dropbox_uploader.sh mkdir ${Main_DB_Dir}${Full_DB_Dir}
/opt/Dropbox-Uploader/dropbox_uploader.sh mkdir ${Main_DB_Dir}${Mysql_DB_Dir}

###############################################################################
######## Creating full mysql backup ###########################################
mysqldump --all-databases > ${Main_Dir}${Mysql_Dir}/dump-$( date '+%Y-%m-%d_%H-%M-%S' ).sql -u root -p${DB_PASSWORD}

#### delete local backups if exceed Backup_Count
if [[ $(ls -1 ${Main_Dir}${Mysql_Dir} | wc -l ) -gt ${Backup_Count} ]]; then
    rm -rf ${Main_Dir}${Mysql_Dir}/$(ls -1 ${Main_Dir}${Mysql_Dir} | head -1 )
fi

#### upload current backups to DropBox
/opt/Dropbox-Uploader/dropbox_uploader.sh -s upload  ${Main_Dir}${Mysql_Dir}/* ${Main_DB_Dir}${Mysql_DB_Dir}

###############################################################################
######## Creating full filesystem pgp backup ##################################
duplicity --encrypt-key ${Gpg_Key} --exclude /bin --exclude /boot --exclude /dev --exclude /lib --exclude /lib64 --exclude /media --exclude /mnt --exclude /proc --exclude /run --exclude /sbin --exclude /srv --exclude /sys --exclude /tmp --exclude /usr --exclude ${Main_Dir} / file://${Main_Dir}${Full_Dir}
tar -rvf ${Main_Dir}${Full_Dir}/full_$(date '+%Y-%m-%d_%H-%M-%S').tar ${Main_Dir}${Full_Dir}
rm -rf ${Main_Dir}${Full_Dir}/duplicity*

#### delete local backups if exceed Backup_Count
if [[ $(ls -1 ${Main_Dir}${Full_Dir} | wc -l ) -gt ${Backup_Count} ]]; then
    rm -rf ${Main_Dir}${Mysql_Dir}/$(ls -1 ${Main_Dir}${Full_Dir} | head -1 )
fi

#### upload current backups to DropBox
/opt/Dropbox-Uploader/dropbox_uploader.sh -s upload  ${Main_Dir}${Full_Dir}/* ${Main_Dir}${Full_DB_Dir}

###############################################################################
######### Delete Oldest mysql backup if backup count is more than 30 backups### 
if [[ $(/opt/Dropbox-Uploader/dropbox_uploader.sh list ${Main_DB_Dir}${Mysql_DB_Dir} | grep dump* |cut -d " " -f4 | wc -l) -gt ${Backup_Count}  ]]
then
	echo "there is more than 30 mysql backups"
        echo "delete Oldest backup"
	/opt/Dropbox-Uploader/dropbox_uploader.sh delete ${Main_DB_Dir}${Mysql_DB_Dir}/$(/opt/Dropbox-Uploader/dropbox_uploader.sh list ${Main_DB_Dir}${Mysql_DB_Dir} | grep dump* |cut -d " " -f4 | head -1)
fi

###############################################################################
########## Delete Oldest full  bakcup if full backup count is more than 15 #### 
if [[ $(/opt/Dropbox-Uploader/dropbox_uploader.sh list ${Main_DB_Dir}${Full_DB_Dir} | grep full_.*tar |cut -d " " -f4 | wc -l) -gt ${Backup_Count} ]]
then
	echo "there is more than 15 backups"
        echo "delete Oldest backup"
	/opt/Dropbox-Uploader/dropbox_uploader.sh delete ${Main_DB_Dir}${Full_DB_Dir}/$(/opt/Dropbox-Uploader/dropbox_uploader.sh list ${Main_DB_Dir}${Full_DB_Dir} | grep full_.*tar |cut -d " " -f4 | head -1)
fi
