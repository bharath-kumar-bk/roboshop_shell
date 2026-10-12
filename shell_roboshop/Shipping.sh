#!/bin/bash

USER_ID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOG_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)   # shipping.sh -> shipping
LOG_FILE="$LOG_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD                           # save this folder now; we cd into /app later
MYSQL_HOST="172.31.36.154"                # private IP of the MySQL server
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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

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

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping code"

cd /app
unzip -o /tmp/shipping.zip &>>$LOG_FILE     # -o overwrites without asking, so re-runs don't hang
VALIDATE $? "Unzipping shipping code"

mvn clean package &>>$LOG_FILE
VALIDATE $? "Building shipping with Maven"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping service file"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Reloading systemd"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enabling shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL client"

# Load the data only if the cities database doesn't exist yet
mysql -h $MYSQL_HOST -uroot -p"$MYSQL_ROOT_PASSWORD" -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h $MYSQL_HOST -uroot -p"$MYSQL_ROOT_PASSWORD" < /app/db/schema.sql &>>$LOG_FILE
    VALIDATE $? "Loading schema"

    mysql -h $MYSQL_HOST -uroot -p"$MYSQL_ROOT_PASSWORD" < /app/db/app-user.sql &>>$LOG_FILE
    VALIDATE $? "Creating app user"

    mysql -h $MYSQL_HOST -uroot -p"$MYSQL_ROOT_PASSWORD" < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading master data"
else
    echo -e "Shipping data already loaded ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "Restarting shipping"