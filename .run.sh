#!/usr/bin/env bash
# Wrapper for running test scripts with proper PATH including yq + python3
export PATH="/home/zhoupei/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
cd /mnt/d/work/zhoupei/harness-foundry
exec "$@"