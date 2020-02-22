# Autossh

## Introduce
Encapsulation ssh tunnel with autologin, `public_key` and `google_authenticator` authentization are supported.

找不到支持用google验证码自动登录的版本，只好自己写了一个，将通过TOTP_SECRET_KEY环境变量将SECRET传进去，我会用python计算出当前的TOKEN，然后用expect自动输入，从而通过ssh验证。ssh tunnel是把瑞士军刀，必须要封装一下以便随时使用。

SSH port forwarding is a mechanism in SSH for tunneling application ports from the client machine to the server machine, or vice versa. It can be used for adding encryption to legacy applications, going through firewalls, and some system administrators and IT professionals use it for opening backdoors into the internal network from their home machines. It can also be abused by hackers and malware to open access from the Internet to the internal network. 

## SSH Tunnel Mode
- L

    Local Forwarding

- R

    Remote Forwarding (Reverse Proxy)

## Quick Start
- Local Forwarding

    Local forwarding is used to forward a port from the client machine to the server machine. Basically, the SSH client listens for connections on a configured port, and when it receives a connection, it tunnels the connection to an SSH server. The server connects to a configurated destination port, possibly on a different machine than the SSH server.

    For example: `LOCAL_HOST:LOCAL_PORT` forward to `REMOTE_HOST:REMOTE_PORT` via `SSH_HOST:SSH_PORT` 

```
#!/bin/sh

CURR_DIR=$(cd `dirname $0` && pwd)

container_name=mysql_proxy
docker stop $container_name
docker rm $container_name
docker run --restart=always -d \
    -p 13306:9066 \
    -v ${CURR_DIR}/id_rsa:/id_rsa \
    -e SSH_MODE=L \
    -e SSH_USER=u001 \
    -e SSH_HOST=172.16.0.1 \
    -e SSH_PORT=22 \
    -e LOCAL_HOST=0.0.0.0 \
    -e LOCAL_PORT=9066 \
    -e REMOTE_HOST=host.of.db.com \
    -e REMOTE_PORT=3306 \
    --name $container_name \
    cnjamesqin/autossh
```


- Remote Forwarding

    In OpenSSH, remote SSH port forwardings are specified using the -R option.For example:

        ssh -R 8080:localhost:80 public.example.com

    This allows anyone on the remote server to connect to TCP port 8080 on the remote server. The connection will then be tunneled back to the client host, and the client then makes a TCP connection to port 80 on localhost. Any other host name or IP address could be used instead of localhost to specify the host to connect to.

    For example: `REMOTE_HOST:REMOTE_PORT` reserse proxy back to `LOCAL_HOST:LOCAL_PORT` via `SSH_HOST:SSH_PORT` 


```
#!/bin/sh

CURR_DIR=$(cd `dirname $0` && pwd)

container_name=ssh_proxy_m
docker stop $container_name
docker rm $container_name
docker run --restart=always \
    -v ${CURR_DIR}/id_rsa:/id_rsa \
    -e SSH_MODE=R \
    -e SSH_USER=u001 \
    -e SSH_HOST=172.16.0.1 \
    -e SSH_PORT=22 \
    -e LOCAL_HOST=192.168.0.101 \
    -e LOCAL_PORT=22 \
    -e REMOTE_HOST=0.0.0.0 \
    -e REMOTE_PORT=60022 \
    -e TOTP_SECRET_KEY=3YMHEMZKDSKZ62Z6NYWI7L2ORY \
    --name $container_name \
    cnjamesqin/autossh
```
