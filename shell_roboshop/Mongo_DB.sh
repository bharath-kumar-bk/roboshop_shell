#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)   # mongodb.sh -> mongodb
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD                           # save current folder, needed to find Mongo.repo later

mkdir -p $LOG_FOLDER                      # -p: no error if the folder already exists

# Only root can install packages
if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1                                # non-zero = failure, stop the script
else
    echo "Running with root access" | tee -a $LOG_FILE
fi

# Checks the exit code of the previous command
# $1 = exit code ($?), $2 = step description
VALIDATE(){
    if [ $1 -eq 0 ]                       # 0 means the command succeeded
    then
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

# Source name must match your file exactly (capital M); destination name can be anything ending in .repo
cp $SCRIPT_DIR/Mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "Copying MongoDB repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod &>>$LOG_FILE      # start automatically on every boot
VALIDATE $? "Enabling MongoDB"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>>$LOG_FILE   # allow other servers to connect, not only localhost
VALIDATE $? "Allowing remote connections"

systemctl restart mongod &>>$LOG_FILE     # restart so the config change applies
VALIDATE $? "Restarting MongoDB"