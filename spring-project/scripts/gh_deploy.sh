#!/bin/bash
set -ex

echo "Current user: $(whoami)" >> $DEPLOY_LOG_PATH
echo "Current user's groups: $(groups)" >> $DEPLOY_LOG_PATH

# 먼저 변수들을 정의합니다.
DEPLOY_DIR="/home/ubuntu/spring-project"
PROJECT_NAME="spring-project"
DEPLOY_LOG_PATH="$DEPLOY_DIR/deploy.log"
DEPLOY_ERR_LOG_PATH="$DEPLOY_DIR/deploy_err.log"
APPLICATION_LOG_PATH="$DEPLOY_DIR/application.log"

# 로그 파일이 존재하지 않으면 생성합니다.
mkdir -p $(dirname $DEPLOY_LOG_PATH)
touch $DEPLOY_LOG_PATH

echo "Deployment script started" >> $DEPLOY_LOG_PATH

# 배포 디렉토리로 이동
cd $DEPLOY_DIR || { echo "Failed to change directory to $DEPLOY_DIR" >> $DEPLOY_ERR_LOG_PATH; exit 1; }
echo "Changed to directory: $(pwd)" >> $DEPLOY_LOG_PATH

JAR_PATH="$DEPLOY_DIR/build/libs/*.jar"

echo "===== 배포 시작 : $(date +%c) =====" >> $DEPLOY_LOG_PATH

echo "Listing build/libs directory:" >> $DEPLOY_LOG_PATH
ls -la $DEPLOY_DIR/build/libs >> $DEPLOY_LOG_PATH 2>> $DEPLOY_ERR_LOG_PATH

BUILD_JAR=$(find $JAR_PATH -name '*.jar' | head -n 1)
if [ -z "$BUILD_JAR" ]; then
    echo "No JAR file found in $JAR_PATH" >> $DEPLOY_ERR_LOG_PATH
    exit 1
fi
JAR_NAME=$(basename $BUILD_JAR)

echo "> build 파일명: $JAR_NAME" >> $DEPLOY_LOG_PATH

echo "> 현재 동작중인 애플리케이션 pid 체크" >> $DEPLOY_LOG_PATH
CURRENT_PID=$(pgrep -f $JAR_NAME)

if [ -z $CURRENT_PID ]
then
  echo "> 현재 동작중인 애플리케이션 존재 X" >> $DEPLOY_LOG_PATH
else
  echo "> 현재 동작중인 애플리케이션 존재 O (PID: $CURRENT_PID)" >> $DEPLOY_LOG_PATH
  echo "> 현재 동작중인 애플리케이션 종료 진행" >> $DEPLOY_LOG_PATH
  kill -15 $CURRENT_PID
  sleep 5
  if kill -0 $CURRENT_PID 2>/dev/null; then
    echo "> 애플리케이션이 정상적으로 종료되지 않았습니다. 강제 종료합니다." >> $DEPLOY_LOG_PATH
    kill -9 $CURRENT_PID
  fi
fi

echo "> $JAR_NAME 배포" >> $DEPLOY_LOG_PATH
nohup java -jar $BUILD_JAR > $APPLICATION_LOG_PATH 2>> $DEPLOY_ERR_LOG_PATH &

DEPLOY_PID=$!
echo "> 배포된 애플리케이션 PID: $DEPLOY_PID" >> $DEPLOY_LOG_PATH

sleep 10

if kill -0 $DEPLOY_PID 2>/dev/null; then
  echo "> 애플리케이션이 성공적으로 실행되었습니다." >> $DEPLOY_LOG_PATH
else
  echo "> 애플리케이션 실행 실패. 로그를 확인하세요." >> $DEPLOY_LOG_PATH
  echo "> 애플리케이션 실행 실패. 로그를 확인하세요." >> $DEPLOY_ERR_LOG_PATH
  exit 1
fi

echo "> 배포 종료 : $(date +%c)" >> $DEPLOY_LOG_PATH
