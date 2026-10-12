#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)   # mysql.sh -> mysql
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
MYSQL_ROOT_PASSWORD="RoboShop@1"

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

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL server"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabling MySQL"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Starting MySQL"

# If this login works, the root password is already set, so skip it
mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql_secure_installation --set-root-pass "$MYSQL_ROOT_PASSWORD" &>>$LOG_FILE
    VALIDATE $? "Setting MySQL root password"
else
    echo -e "MySQL root password already set ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi