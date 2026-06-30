#!/bin/bash
# harness-docker.sh - Docker 执行环境 Provider
#
# 参考 execution-context provider-protocol.md
# 实现 provision / destroy / health 三个核心操作
#
# 用法:
#   bash scripts/harness-docker.sh provision <domain> [workspace_path]
#   bash scripts/harness-docker.sh destroy <container_name>
#   bash scripts/harness-docker.sh health <container_name>
#   bash scripts/harness-docker.sh list

set -euo pipefail

OPERATION="${1:-}"
TARGET="${2:-}"
WORKSPACE="${3:-$(pwd)}"

DOCKER_IMAGE="harness-sandbox:latest"
CONTAINER_PREFIX="harness-"

# 检查 Docker 是否可用
check_docker() {
  if ! command -v docker &> /dev/null; then
    echo "[harness-docker] ERROR: Docker 不可用"
    exit 1
  fi
}

# 检查镜像是否存在
check_image() {
  if ! docker image inspect "$DOCKER_IMAGE" > /dev/null 2>&1; then
    echo "[harness-docker] WARN: 镜像 $DOCKER_IMAGE 不存在"
    echo "[harness-docker] 运行 'docker build -t $DOCKER_IMAGE -f Dockerfile.harness .' 构建"
    return 1
  fi
  return 0
}

case "$OPERATION" in
  provision)
    check_docker
    DOMAIN="$TARGET"
    CONTAINER_NAME="${CONTAINER_PREFIX}${DOMAIN}-$(date +%Y%m%d%H%M%S)-$$"

    echo "[harness-docker] Provision: domain=$DOMAIN, container=$CONTAINER_NAME"

    check_image || {
      echo "[harness-docker] 使用 ubuntu:22.04 作为 fallback"
      DOCKER_IMAGE="ubuntu:22.04"
    }

    # 创建容器
    CONTAINER_ID=$(docker run -d \
      --name "$CONTAINER_NAME" \
      --cpus="2" \
      --memory="2g" \
      --network=none \
      --read-only \
      --tmpfs /tmp:rw,noexec,nosuid,size=512m \
      -v "$WORKSPACE:/workspace:ro" \
      "$DOCKER_IMAGE" \
      sleep infinity 2>/dev/null || echo "")

    if [ -z "$CONTAINER_ID" ]; then
      echo "[harness-docker] ERROR: 容器创建失败"
      exit 1
    fi

    echo "{\"id\":\"docker-${DOMAIN}-$(date +%s)\",\"provider\":\"docker\",\"container_name\":\"${CONTAINER_NAME}\",\"container_id\":\"${CONTAINER_ID}\",\"workspace\":\"/workspace\"}"
    ;;

  destroy)
    check_docker
    CONTAINER_NAME="$TARGET"

    echo "[harness-docker] Destroy: container=$CONTAINER_NAME"

    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      docker rm -f "$CONTAINER_NAME" > /dev/null 2>&1
      echo "[harness-docker] 容器 $CONTAINER_NAME 已销毁"
    else
      echo "[harness-docker] WARN: 容器 $CONTAINER_NAME 不存在"
    fi
    ;;

  health)
    check_docker
    CONTAINER_NAME="$TARGET"

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      echo "[harness-docker] HEALTHY: 容器 $CONTAINER_NAME 运行中"
    elif docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      echo "[harness-docker] UNHEALTHY: 容器 $CONTAINER_NAME 已停止"
    else
      echo "[harness-docker] UNHEALTHY: 容器 $CONTAINER_NAME 不存在"
    fi
    ;;

  list)
    check_docker
    echo "[harness-docker] 活跃容器:"
    docker ps --format '{{.Names}}\t{{.Status}}\t{{.Image}}' | grep "^${CONTAINER_PREFIX}" || echo "  (无)"
    ;;

  *)
    echo "用法: bash scripts/harness-docker.sh {provision|destroy|health|list} <target> [workspace]"
    echo ""
    echo "  provision <domain> [path]  - 创建新的 Docker 沙箱"
    echo "  destroy <container_name>   - 销毁容器"
    echo "  health <container_name>    - 检查容器健康状态"
    echo "  list                       - 列出所有 harness 容器"
    exit 1
    ;;
esac
