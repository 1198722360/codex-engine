#!/bin/sh
set -eu
umask 077

redis_secret=$(cat /run/secrets/redis-password)
case "$redis_secret" in
  *[!a-f0-9]*|'') exit 1 ;;
esac

cat > /data/dispatcher.conf <<EOF
bind 0.0.0.0
protected-mode yes
port 6379
requirepass $redis_secret
maxmemory 64mb
maxmemory-policy allkeys-lru
save ""
appendonly no
EOF
chown redis:redis /data/dispatcher.conf
unset redis_secret
exec /usr/local/bin/docker-entrypoint.sh redis-server /data/dispatcher.conf
