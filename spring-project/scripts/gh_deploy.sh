#!/bin/bash
set -ex

# pgrep 테스트
echo "Testing pgrep command..."
SSHD_PID=$(pgrep -f sshd)
if [ -z "$SSHD_PID" ]; then
    echo "Failed to execute pgrep or find sshd process"
else
    echo "pgrep test successful. Found sshd process with PID: $SSHD_PID"
fi

# 변수 정의
DEPLOY_DIR="/home/ubuntu/spring-project"
PROJECT_NAME="spring-project"
DEPLOY_LOG_PATH="$DEPLOY_DIR/deploy.log"
DEPLOY_ERR_LOG_PATH="$DEPLOY_DIR/deploy_err.log"
APPLICATION_LOG_PATH="$DEPLOY_DIR/application.log"

# 디렉토리 및 로그 파일 설정
sudo mkdir -p $DEPLOY_DIR
sudo chown ubuntu:ubuntu $DEPLOY_DIR
sudo chmod 755 $DEPLOY_DIR
sudo -u ubuntu touch $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH
sudo chmod 644 $DEPLOY_LOG_PATH $DEPLOY_ERR_LOG_PATH $APPLICATION_LOG_PATH

echo "Deployment script started" >> "$DEPLOY_LOG_PATH"

# 배포 디렉토리로 이동
cd $DEPLOY_DIR || { echo "Failed to change directory to $DEPLOY_DIR" >> $DEPLOY_ERR_LOG_PATH; exit 1; }

JAR_PATH="$DEPLOY_DIR/build/libs/*.jar"
echo "===== 배포 시작 : $(date +%c) =====" >> $DEPLOY_LOG_PATH

# JAR 파일 찾기
BUILD_JAR=$(find $JAR_PATH -name '*.jar' | head -n 1)
if [ -z "$BUILD_JAR" ]; then
  echo "No JAR file found in $JAR_PATH" >> $DEPLOY_ERR_LOG_PATH
  exit 1
fi
JAR_NAME=$(basename $BUILD_JAR)

echo "> build 파일명: $JAR_NAME" >> $DEPLOY_LOG_PATH

echo "All Java processes:" >> $DEPLOY_LOG_PATH
jps -l >> $DEPLOY_LOG_PATH
echo "All processes containing 'spring-project':" >> $DEPLOY_LOG_PATH
ps aux | grep "[s]pring-project" >> $DEPLOY_LOG_PATH

# JAR 프로세스 찾기
CURRENT_PID=$(pgrep -f "$JAR_NAME" || echo "")
echo "Found PIDs: $CURRENT_PID" >> "$DEPLOY_LOG_PATH"

if [ -z "$CURRENT_PID" ]; then
    echo "No running process found" >> "$DEPLOY_LOG_PATH"
else
    echo "Attempting to stop process(es) with PID(s): $CURRENT_PID" >> "$DEPLOY_LOG_PATH"
    for pid in $CURRENT_PID; do
        if kill -15 "$pid" 2>/dev/null; then
            echo "Successfully sent SIGTERM to PID $pid" >> "$DEPLOY_LOG_PATH"
        else
            echo "Failed to send SIGTERM to PID $pid" >> "$DEPLOY_LOG_PATH"
        fi
    done
    sleep 5
    for pid in $CURRENT_PID; do
        if kill -0 "$pid" 2>/dev/null; then
            echo "Process $pid still running, sending SIGKILL" >> "$DEPLOY_LOG_PATH"
            kill -9 "$pid"
        fi
    done
fi

# 새 프로세스 시작
echo "Starting new process" >> "$DEPLOY_LOG_PATH"
nohup java -jar "$BUILD_JAR" > "$APPLICATION_LOG_PATH" 2>> "$DEPLOY_ERR_LOG_PATH" &
DEPLOY_PID=$!
echo "New process started with PID: $DEPLOY_PID" >> "$DEPLOY_LOG_PATH"

sleep 10

if kill -0 "$DEPLOY_PID" 2>/dev/null; then
    echo "New process is still running after 10 seconds" >> "$DEPLOY_LOG_PATH"
else
    echo "New process failed to start or terminated quickly" >> "$DEPLOY_LOG_PATH"
    exit 1
fi
