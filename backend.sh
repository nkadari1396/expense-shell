#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USER_ID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

CHECK_ROOT(){
    if [ $USER_ID -ne 0 ]
    then
        echo -e "Please run this script with root privileges" &>>$LOG_FILE
        exit 1
    fi
    
    }

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e $2 is... $R FAILED $N | tee -a $LOG_FILE
    else
        echo -e $2 is... $G SUCCESS $N | tee -a $LOG_FILE
    fi

}

echo "script started excuting at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf module enable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable deault nodejs"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIADATE $? "Install nodejs"

id expense &>>$LOG_FILE

if [ $? -ne 0 ]
then
    echo -e "expense user not exsists.. $G Creating $N"
    useradd expense &>>$LOG_FILE
    VALIDATE $? "Creating expense user"
else
    echo -e "expense user alraedy exsist... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating /app folder"

curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip &>>$LOG_FILE
VALIDATE $? "Downloading backend application code"

cd /app
rm -rf /app/*
unzip /tmp/backend.zip &>>$LOG_FILE
VALIDATE $? "Extracting backend application code"

npm install &>>$LOG_FILE
cp /home/ec2-user/expense-shell/backend.service /etc/systemd/system/backend.service

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "Installing MySQL client"

mysql -h mysql.naveenkadari.com -uroot -pExpenseAPP@1 < /app/schema/backend.sql &>>$LOG_FILE
VALIDATE $? "Schema loading"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Schema loading"

systemctl enable backend &>>$LOG_FILE
VALIDATE $? "Enabled backend"

systemctl restart backend &>>$LOG_FILE
VALIDATE $? "restart backend"


