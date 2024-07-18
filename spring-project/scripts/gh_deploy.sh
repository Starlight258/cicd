#!/bin/bash
set -ex

# 먼저 변수들을 정의합니다.
DEPLOY_DIR="/home/ubuntu/spring-project"
PROJECT_NAME="spring-project"
DEPLOY_LOG_PATH="$DEPLOY_DIR/deploy.log"
DEPLOY_ERR_LOG_PATH="$DEPLOY_DIR/deploy_err.log"
APPLICATION_LOG_PATH="$DEPLOY_DIR/application.log"

# 변수 설정 확인
echo "DEPLOY_DIR: $DEPLOY_DIR"
echo "PROJECT_NAME: $PROJECT_NAME"
echo "DEPLOY_LOG_PATH: $DEPLOY_LOG_PATH"
echo "DEPLOY_ERR_LOG_PATH: $DEPLOY_ERR_LOG_PATH"
echo "APPLICATION_LOG_PATH: $APPLICATION_LOG_PATH"

# 현재 사용자 및 작업 디렉토리 확인
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "Contents of current directory: $(ls -la)"

# 로그 디렉토리 생성 및 권한 설정
# 디렉토리 생성 및 권한 설정
sudo mkdir -p $DEPLOY_DIR
sudo chown ubuntu:ubuntu $DEPLOY_DIR
sudo chmod 755 $DEPLOY_DIR

# 로그 파일 생성 및 권한 설정
sudo -u ubuntu touch $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH
sudo chmod 644 $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH

# 현재 사용자 및 디렉토리 정보 출력
sudo -u ubuntu bash <<EOF
echo "Current user: $(whoami)"
echo "Current directory: $(pwd)"
echo "Contents of deploy directory: $(ls -la $DEPLOY_DIR)"
EOF

echo "Deployment script started" >>"$DEPLOY_LOG_PATH"

# 배포 디렉토리로 이동
cd $DEPLOY_DIR || {
  echo "Failed to change directory to $DEPLOY_DIR" >>$DEPLOY_ERR_LOG_PATH
  exit 1
}
echo "Changed to directory: $(pwd)" >>$DEPLOY_LOG_PATH

JAR_PATH="$DEPLOY_DIR/build/libs/*.jar"

echo "===== 배포 시작 : $(date +%c) =====" >>$DEPLOY_LOG_PATH

echo "Listing build/libs directory:" >>$DEPLOY_LOG_PATH
ls -la $DEPLOY_DIR/build/libs >>$DEPLOY_LOG_PATH 2>>$DEPLOY_ERR_LOG_PATH

BUILD_JAR=$(find $JAR_PATH -name '*.jar' | head -n 1)
if [ -z "$BUILD_JAR" ]; then
  echo "No JAR file found in $JAR_PATH" >>$DEPLOY_ERR_LOG_PATH
  exit 1
fi
JAR_NAME=$(basename $BUILD_JAR)

echo "> build 파일명: $JAR_NAME" >>$DEPLOY_LOG_PATH

echo "> 현재 동작중인 애플리케이션 pid 체크" >>$DEPLOY_LOG_PATH
CURRENT_PID=$(pgrep -f $JAR_NAME)

if [ -z $CURRENT_PID ]; then
  echo "> 현재 동작중인 애플리케이션 존재 X" >>$DEPLOY_LOG_PATH
else
  echo "> 현재 동작중인 애플리케이션 존재 O (PID: $CURRENT_PID)" >>$DEPLOY_LOG_PATH
  echo "> 현재 동작중인 애플리케이션 종료 진행" >>$DEPLOY_LOG_PATH
  kill -15 $CURRENT_PID
  sleep 5
  if kill -0 $CURRENT_PID 2>/dev/null; then
    echo "> 애플리케이션이 정상적으로 종료되지 않았습니다. 강제 종료합니다." >>$DEPLOY_LOG_PATH
    kill -9 $CURRENT_PID
  fi
fi

echo "> $JAR_NAME 배포" >>$DEPLOY_LOG_PATH
nohup java -jar $BUILD_JAR >$APPLICATION_LOG_PATH 2>>$DEPLOY_ERR_LOG_PATH &

DEPLOY_PID=$!
echo "> 배포된 애플리케이션 PID: $DEPLOY_PID" >>$DEPLOY_LOG_PATH

sleep 10

if kill -0 $DEPLOY_PID 2>/dev/null; then
  echo "> 애플리케이션이 성공적으로 실행되었습니다." >>$DEPLOY_LOG_PATH
else
  echo "> 애플리케이션 실행 실패. 로그를 확인하세요." >>$DEPLOY_LOG_PATH
  echo "> 애플리케이션 실행 실패. 로그를 확인하세요." >>$DEPLOY_ERR_LOG_PATH
  exit 1
fi

echo "> 배포 종료 : $(date +%c)" >>$DEPLOY_LOG_PATH
