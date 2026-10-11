#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD                           # save this folder now; we cd into the nginx folder later

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

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling default nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling nginx 1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOG_FILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE    # remove the default page
VALIDATE $? "Removing default content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Unzipping frontend code"

# The file name here must match your file exactly (Linux is case-sensitive)
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf
VALIDATE $? "Copying nginx config"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting nginx"