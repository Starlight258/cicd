#!/bin/bash
set -e

echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "Script location: $0"

# 배포된 애플리케이션 디렉토리로 이동
DEPLOY_DIR="/home/ubuntu/spring-project"
cd $DEPLOY_DIR

echo "Changed to directory: $(pwd)"

PROJECT_NAME="spring-project"
JAR_PATH="$DEPLOY_DIR/build/libs/*.jar"
DEPLOY_LOG_PATH="$DEPLOY_DIR/deploy.log"
DEPLOY_ERR_LOG_PATH="$DEPLOY_DIR/deploy_err.log"
APPLICATION_LOG_PATH="$DEPLOY_DIR/application.log"

echo "===== 배포 시작 : $(date +%c) =====" >> $DEPLOY_LOG_PATH

# JAR 파일 찾기
BUILD_JAR=$(find $JAR_PATH -name '*.jar' | head -n 1)
JAR_NAME=$(basename $BUILD_JAR)

echo "> build 파일명: $JAR_NAME" >> $DEPLOY_LOG_PATH

echo "> 현재 동작중인 애플리케이션 pid 체크" >> $DEPLOY_LOG_PATH
CURRENT_PID=$(pgrep -f $JAR_NAME)

if [ -z $CURRENT_PID ]
then
  echo "> 현재 동작중인 애플리케이션 존재 X" >> $DEPLOY_LOG_PATH
else
  echo "> 현재 동작중인 애플리케이션 존재 O" >> $DEPLOY_LOG_PATH
  echo "> 현재 동작중인 애플리케이션 강제 종료 진행" >> $DEPLOY_LOG_PATH
  kill -15 $CURRENT_PID
  sleep 5
fi

echo "> $JAR_NAME 배포" >> $DEPLOY_LOG_PATH
nohup java -jar $BUILD_JAR >> $APPLICATION_LOG_PATH 2> $DEPLOY_ERR_LOG_PATH &

sleep 3

echo "> 배포 종료 : $(date +%c)" >> $DEPLOY_LOG_PATH
