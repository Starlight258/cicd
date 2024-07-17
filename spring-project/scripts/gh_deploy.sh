#!/bin/bash
set -e

# 필요한 디렉토리 생성 및 권한 설정
sudo mkdir -p /home/ubuntu/spring-project
sudo chown -R ubuntu:ubuntu /home/ubuntu/spring-project
sudo chmod -R 755 /home/ubuntu/spring-project

PROJECT_NAME="spring-project"
JAR_PATH="/home/ubuntu/spring-project/build/libs/*.jar"
DEPLOY_PATH=/home/ubuntu/$PROJECT_NAME/
DEPLOY_LOG_PATH="/home/ubuntu/$PROJECT_NAME/deploy.log"
DEPLOY_ERR_LOG_PATH="/home/ubuntu/$PROJECT_NAME/deploy_err.log"
APPLICATION_LOG_PATH="/home/ubuntu/$PROJECT_NAME/application.log"

# 로그 파일 생성 및 권한 설정
sudo touch $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH
sudo chown ubuntu:ubuntu $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH
sudo chmod 644 $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH

BUILD_JAR=$(ls $JAR_PATH)
JAR_NAME=$(basename $BUILD_JAR)

echo "===== 배포 시작 : $(date +%c) =====" >> $DEPLOY_LOG_PATH

echo "> build 파일명: $JAR_NAME" >> $DEPLOY_LOG_PATH
echo "> build 파일 복사" >> $DEPLOY_LOG_PATH
sudo cp $BUILD_JAR $DEPLOY_PATH

echo "> 현재 동작중인 어플리케이션 pid 체크" >> $DEPLOY_LOG_PATH
CURRENT_PID=$(pgrep -f $JAR_NAME)

if [ -z $CURRENT_PID ]
then
  echo "> 현재 동작중인 어플리케이션 존재 X" >> $DEPLOY_LOG_PATH
else
  echo "> 현재 동작중인 어플리케이션 존재 O" >> $DEPLOY_LOG_PATH
  echo "> 현재 동작중인 어플리케이션 강제 종료 진행" >> $DEPLOY_LOG_PATH
  echo "> kill -9 $CURRENT_PID" >> $DEPLOY_LOG_PATH
  sudo kill -9 $CURRENT_PID
fi

DEPLOY_JAR=$DEPLOY_PATH$JAR_NAME
echo "> DEPLOY_JAR 배포" >> $DEPLOY_LOG_PATH
sudo nohup java -jar $DEPLOY_JAR >> $APPLICATION_LOG_PATH 2> $DEPLOY_ERR_LOG_PATH &

sleep 3

echo "> 배포 종료 : $(date +%c)" >> $DEPLOY_LOG_PATH
