FROM alpine:3

# Non root user details
ARG USERNAME=reverse_proxy
ARG USER_UID=5001
ARG USER_GID=${USER_UID}
ARG CERT_DIR=/etc/your-dir/certificates/server

COPY ./yourcert/dhparam.pem /etc/ssl/certs/
COPY proxy.conf /etc/nginx/default.template
COPY entrypoint.sh /

RUN apk -U upgrade \
    && apk add --no-cache \
        curl \
        gettext \
        nginx \
        openssl \
    # Add user account
    && addgroup -g $USER_GID $USERNAME \
    && adduser --system --shell /bin/sh -u $USER_UID -G $USERNAME $USERNAME \
    # Redirect nginx logs to stdout / stderr
    && ln -s /dev/stdout /var/log/nginx/access.log \
    && ln -s /dev/stderr /var/log/nginx/error.log \
    && rm /etc/nginx/http.d/default.conf \
    # Change log files / nginx.pid file so nginx can run as non-root user
    && sed -i -e '/user/!b' -e '/nginx/!b' -e '/nginx/d' /etc/nginx/nginx.conf \
    && sed -i 's!/var/run/nginx.pid!/tmp/nginx.pid!g' /etc/nginx/nginx.conf \
    && sed -i "/^http {/a \    proxy_temp_path /tmp/proxy_temp;\n    client_body_temp_path /tmp/client_temp;\n    fastcgi_temp_path /tmp/fastcgi_temp;\n    uwsgi_temp_path /tmp/uwsgi_temp;\n    scgi_temp_path /tmp/scgi_temp;\n" /etc/nginx/nginx.conf \
    && sed  -i "/events/i pid\t/tmp/nginx.pid;\n" /etc/nginx/nginx.conf \
    # Change nginx include config location to tmp
    && pattern='include \/etc\/nginx\/http.d\/\*.conf;' \
    && new_value='include \/tmp\/nginx\/conf.d\/*.conf;' \
    && sed -i "s/$pattern/$new_value/" /etc/nginx/nginx.conf \
    # Change owner of nginx conf and var folder & add group write permission
    && chown ${USER_UID}:0 /var/lib/nginx \
    && chmod 775 /var/lib/nginx \
    && chown ${USER_UID}:0 /etc/nginx/http.d \
    && chmod 775 /etc/nginx/http.d \
    # Create certificate path
    && mkdir -p ${CERT_DIR} \
    && chown ${USER_UID}:0 ${CERT_DIR} \
    # Set permissions on copied files
    && chown ${USER_UID}:0 /etc/ssl/certs/dhparam.pem \
    && chown ${USER_UID}:0 /etc/nginx/default.template \
    && chown ${USER_UID}:0 /entrypoint.sh \
    && chmod 550 /entrypoint.sh


ENV HTTP_PORT=8080 \
    HTTPS_PORT=8443 \
    SERVER_NAME=YOURSERVERNAME.com \
    PROXY_PROTOCOL=http \
    PROXY_UPSTREAM=flask_app:5000 \
    SERVER_ENV=development \
    KEEP_ALIVE_TIMEOUT=620
    # https://cloud.google.com/load-balancing/docs/https

USER ${USERNAME}:${USER_GID}

HEALTHCHECK --interval=10s --timeout=10s --retries=3 CMD curl --fail https://localhost:${HTTPS_PORT}/web-health -ksS|| exit 1
ENTRYPOINT ["/bin/sh", "/entrypoint.sh"]
