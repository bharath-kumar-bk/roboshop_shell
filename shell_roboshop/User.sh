#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)   # user.sh -> user
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD                           # save this folder now; we cd into /app later

mkdir -p $LOG_FOLDER

if [ $USER_ID -ne 0 ]
then
    echo -e "$R ERROR:: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "Running with root access" | tee -a $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disabling default NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enabling NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS"

# useradd fails if the user already exists, so create it only when missing
id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating roboshop system user"
else
    echo -e "roboshop user already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app
VALIDATE $? "Creating /app folder"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user code"

cd /app
unzip -o /tmp/user.zip &>>$LOG_FILE     # -o overwrites without asking, so re-runs don't hang
VALIDATE $? "Unzipping user code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service
VALIDATE $? "Copying user service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd"

systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enabling user"

systemctl start user &>>$LOG_FILE
VALIDATE $? "Starting user"