#!/bin/sh

LOCAL_HOST=${LOCAL_HOST:-0.0.0.0}
LOCAL_PORT=${LOCAL_PORT:-9066}
REMOTE_HOST=${REMOTE_HOST:-0.0.0.0}

SSH_PORT=${SSH_PORT:-22}
SSH_KEY_FILE=${SSH_KEY_FILE:=/id_rsa}

SSH_OPTION=' -o StrictHostKeyChecking=no -o ServerAliveInterval=5 -o ServerAliveCountMax=3 '
SSH_MODE=${SSH_MODE:-R}

if [ -f "${SSH_KEY_FILE}" ]; then
    SSH_OPTION="${SSH_OPTION} -i ${SSH_KEY_FILE}"
fi

if [ $SSH_MODE = 'R' ]; then
    echo "[`date +%F_%T`][INFO] Remote revers proxy mode"
    echo "[`date +%F_%T`][INFO] Specifying a remote remote bind_address(${REMOTE_HOST}:${REMOTE_PORT}) will only succeed if the server's GatewayPorts option is enabled."
    cmd="autossh -M 0 -NTR ${REMOTE_HOST}:${REMOTE_PORT}:${LOCAL_HOST}:${LOCAL_PORT} ${SSH_OPTION} -p${SSH_PORT} ${SSH_USER}@${SSH_HOST}"
else
    echo "[`date +%F_%T`][INFO] Local forward mode"
    cmd="autossh -M -0 -NTL ${LOCAL_HOST}:${LOCAL_PORT}:${REMOTE_HOST}:${REMOTE_PORT} ${SSH_OPTION} -p${SSH_PORT} ${SSH_USER}@${SSH_HOST}"
fi

echo "[`date +%F_%T`][INFO] Exec: $cmd"

if [ "x$TOTP_SECRET_KEY" = "x" ]; then
    exec $cmd
else
    /usr/bin/expect <<-EOF
set TOTP_TOKEN ""
set LAST_TOTP_TOKEN "unused"

set timeout -1
spawn $cmd
expect {
    -nocase "yes/no" {
        send "yes\r" 
        exp_continue 
    }
    -nocase "Connection closed" {
        puts "Maybe the retry times exceed the ssh server's limit, sleep 30 seconds and then container will auto restart"
        sleep 30
        exit -1
    }
    -nocase "disconnect" {
        puts "Maybe the retry times exceed the ssh server's limit, sleep 30 seconds and then container will auto restart"
        sleep 30
        exit -2
    }
    -nocase "Permission denied" { 
        puts "Maybe the retry times exceed the ssh server's limit, sleep 30 seconds and then container will auto restart"
        sleep 30
        exit -3
    }
    -nocase "Verification code:" {
        for {set i 0} {\$i < 30} {incr i} {
            set TOTP_TOKEN [exec sh -c {python /app/GoogleAuthenticator.py ${TOTP_SECRET_KEY} }]
            if { \$TOTP_TOKEN == \$LAST_TOTP_TOKEN } {
                puts "\[[exec date +%F_%T]\]\[INFO\] Wait for MFA code change..."
                sleep 2
                continue
            }
            break
        }
        puts "\$TOTP_TOKEN"
        send "\$TOTP_TOKEN\r"
        set LAST_TOTP_TOKEN \$TOTP_TOKEN
        exp_continue
    }
}
expect eof
EOF
fi

echo "[`date +%F_%T`][INFO] entrypoint.sh exit"

