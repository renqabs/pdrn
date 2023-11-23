# 使用基础镜像
FROM golang:alpine AS builder

# 安装必要的工具
RUN apk update && apk add --no-cache \
    curl \
    tar  \
    jq

# 创建新的工作目录
WORKDIR /app

# 下载并解压文件，并给予所有用户读写和执行权限
RUN latest_url=$(curl "https://api.github.com/repos/pandora-next/deploy/releases/latest" | jq -r '.assets[] | select(.name | contains("amd64")) | .browser_download_url' | head -n 1) \
    && curl -Lo PandoraNext.tar.gz $latest_url \
    && tar -xzf PandoraNext.tar.gz --strip-components=1 \
    && rm PandoraNext.tar.gz \
    && chmod 777 -R .
    
# 等待3分钟，获取授权
# RUN sleep 1m\
RUN --mount=type=secret,id=LICENSE_URL,dst=/etc/secrets/LICENSE_URL \
    curl -fLO https://dash.pandoranext.com/data/$(cat /etc/secrets/LICENSE_URL)/license.jwt
RUN chmod 777 license.jwt

# 下载config.json文件，并给予所有用户读写和执行权限
COPY config.json .
RUN chmod 777 config.json

# 修改PandoraNext的执行权限
RUN chmod 777 ./PandoraNext

# 创建全局缓存目录并提供最宽松的权限
RUN mkdir /.cache && chmod 777 /.cache

# 开放端口
EXPOSE 8080

# 启动命令
CMD ["./PandoraNext"]
