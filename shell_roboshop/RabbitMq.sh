#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)   # rabbitmq.sh -> rabbitmq
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD                           # save this folder; needed to find rabbitmq.repo
RABBITMQ_PASSWORD="roboshop123"

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

# The repo file checks package signatures, so import the keys first
rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/rabbitmq-release-signing-key.asc' &>>$LOG_FILE
VALIDATE $? "Importing RabbitMQ signing key"

rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key' &>>$LOG_FILE
VALIDATE $? "Importing Erlang signing key"

rpm --import 'https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key' &>>$LOG_FILE
VALIDATE $? "Importing RabbitMQ server signing key"

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Adding RabbitMQ repo"

dnf install erlang rabbitmq-server -y &>>$LOG_FILE
VALIDATE $? "Installing RabbitMQ server"

systemctl enable rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Enabling RabbitMQ server"

systemctl start rabbitmq-server &>>$LOG_FILE
VALIDATE $? "Starting RabbitMQ server"

# add_user fails if the user already exists, so create it only when missing
rabbitmqctl list_users | grep -w roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD &>>$LOG_FILE
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
VALIDATE $? "Setting permissions"