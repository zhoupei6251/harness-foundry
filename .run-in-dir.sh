#!/usr/bin/env bash
# Wrapper to run a command in harness-foundry dir with proper PATH
set -e
export PATH="/home/zhoupei/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
cd /mnt/d/work/zhoupei/harness-foundry
exec "$@"