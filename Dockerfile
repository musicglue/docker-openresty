FROM ubuntu:16.04

ENV OPENRESTY_VERSION=1.11.2.5 \
    LUAROCKS_VERSION=2.3.0 \
    OPENRESTY_PREFIX=/app \
    NGINX_PREFIX=/app/nginx \
    VAR_PREFIX=/app/var/nginx \
    NODE_ENV=production \
    PATH=/app/bin:/app/nginx/bin:$PATH \
    MANAGEMENT_CONFIG_PATH=/conf/management.conf

RUN apt update \
 && apt upgrade -y \
 && apt dist-upgrade -y \
 && apt install -y openssl libssl-dev libpcre3-dev libpcre++-dev curl wget build-essential unzip

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt install -y nodejs

WORKDIR $OPENRESTY_PREFIX
RUN mkdir -p /tmp/ngx_openresty \
 && cd /tmp/ngx_openresty \
 && echo "==> Downloading OpenResty..." \
 && curl -sSL https://openresty.org/download/openresty-${OPENRESTY_VERSION}.tar.gz | tar -xvz \
 && cd openresty-* \
 && echo "==> Configuring OpenResty..." \
 && readonly NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && echo "using upto $NPROC threads" \
 && ./configure \
    --prefix=$OPENRESTY_PREFIX \
    --http-client-body-temp-path=$VAR_PREFIX/client_body_temp \
    --http-proxy-temp-path=$VAR_PREFIX/proxy_temp \
    --http-log-path=$VAR_PREFIX/access.log \
    --error-log-path=$VAR_PREFIX/error.log \
    --pid-path=$VAR_PREFIX/nginx.pid \
    --lock-path=$VAR_PREFIX/nginx.lock \
    --with-luajit \
    --with-pcre-jit \
    --with-ipv6 \
    --with-http_ssl_module \
    --with-http_realip_module \
    --with-http_v2_module \
    --with-stream \
    --with-http_stub_status_module \
    --without-http_split_clients_module \
    --without-http_upstream_ip_hash_module \
    --without-http_userid_module \
    --without-http_auth_basic_module \
    --without-http_ssi_module \
    --without-http_userid_module \
    --without-http_uwsgi_module \
    --without-http_scgi_module \
    -j${NPROC} \
 && echo "==> Building OpenResty..." \
 && make -j${NPROC} \
 && echo "==> Installing OpenResty..." \
 && make install \
 && echo "==> Finishing..." \
 && mkdir -p $OPENRESTY_PREFIX/bin \
 && ln -sf $NGINX_PREFIX/sbin/nginx $OPENRESTY_PREFIX/bin/nginx \
 && ln -sf $NGINX_PREFIX/sbin/nginx $OPENRESTY_PREFIX/bin/openresty \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/luajit/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/bin/lua \
 && ln -sf $OPENRESTY_PREFIX/luajit/bin/luajit-* $OPENRESTY_PREFIX/bin/luajit \
 && cd - \
 && wget http://luarocks.org/releases/luarocks-$LUAROCKS_VERSION.tar.gz \
 && tar -xzvf luarocks-$LUAROCKS_VERSION.tar.gz \
 && cd luarocks-* \
 && ./configure --prefix=$OPENRESTY_PREFIX/luajit \
      --with-lua=$OPENRESTY_PREFIX/luajit/ \
      --lua-suffix=jit-2.1.0-beta3 \
      --with-lua-include=$OPENRESTY_PREFIX/luajit/include/luajit-2.1 \
 && make \
 && make install \
 && ln -s $OPENRESTY_PREFIX/luajit/bin/luarocks $OPENRESTY_PREFIX/bin/luarocks \
 && cd /tmp \
 && rm -rf luarocks* \
 && rm -rf /var/cache/apk/* \
 && rm -rf /tmp/ngx_openresty \
 && cd $NGINX_PREFIX \
 && rm -rf conf html

RUN mkdir -p /app/nginx/conf/server.d
ADD bin /bin/
ADD conf/ /app/nginx/conf/server.d/
ENTRYPOINT ["/bin/pid1"]
