#!/bin/sh
CERT_DIR='/etc/your-dir/certificates/server'
CERT_PATH="$CERT_DIR/PUBLIC.pem"
KEY_PATH="$CERT_DIR/PRIVATE.pem"
CONF_PATH='/tmp/nginx/conf.d/default.conf'

mkdir /tmp/nginx/conf.d -p

envsubst '$PROXY_PROTOCOL,$PROXY_UPSTREAM,$HTTP_PORT,$HTTPS_PORT,$SERVER_NAME,$KEEP_ALIVE_TIMEOUT' < /etc/nginx/default.template > $CONF_PATH

if [ ! -f $CONF_PATH ]; then
    echo "Error generating nginx proxy config: $CONF_PATH."
    exit 2
fi

word_count=$(cat $CONF_PATH | wc -w) 
if [ "$word_count" -eq "0" ]; then
    echo "Error writing nginx proxy config: $CONF_PATH. Empty file."
    exit 3
fi

if [ ! -f $CERT_PATH ] && [ "$SERVER_ENV" == "development" ]; then
    echo "Creating self signed certificate..."
    openssl req -new -newkey rsa:2048 -nodes -days 28 -x509 \
        -subj "/C=CA/ST=Ontario/L=California/O=YourOU INC./CN=$SERVER_NAME" \
        -keyout $KEY_PATH \
        -out $CERT_PATH
fi

exec /usr/sbin/nginx -g 'daemon off;'
