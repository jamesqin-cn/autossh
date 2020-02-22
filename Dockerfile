FROM python:2.7-alpine

COPY . /app/

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && apk --no-cache add autossh expect \
    && chmod +x /app/*.sh

EXPOSE 9066

ENTRYPOINT ["/app/entrypoint.sh"]
