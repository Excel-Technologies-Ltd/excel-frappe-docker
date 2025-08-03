#!/bin/bash
# Set variables that do not exist

# Generate a simple unique ID without uuidgen
generate_uuid() {
  cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(date +%s)-$(shuf -i 1000-9999 -n 1)"
}

if [[ -z "$FRONTEND_ID" ]]; then
  # Use hostname or container name as frontend ID
  export FRONTEND_ID="${HOSTNAME:-$(generate_uuid)}"
  echo "FRONTEND_ID set to: $FRONTEND_ID"
fi

if [[ -z "$REQUEST_ID" ]]; then
  export REQUEST_ID="req-$(generate_uuid)"
  echo "REQUEST_ID set to: $REQUEST_ID"
fi

if [[ -z "$BACKEND" ]]; then
  echo "BACKEND defaulting to 0.0.0.0:8000"
  export BACKEND=0.0.0.0:8000
fi

if [[ -z "$SOCKETIO" ]]; then
  echo "SOCKETIO defaulting to 0.0.0.0:9000"
  export SOCKETIO=0.0.0.0:9000
fi

if [[ -z "$UPSTREAM_REAL_IP_ADDRESS" ]]; then
  echo "UPSTREAM_REAL_IP_ADDRESS defaulting to 127.0.0.1"
  export UPSTREAM_REAL_IP_ADDRESS=127.0.0.1
fi

if [[ -z "$UPSTREAM_REAL_IP_HEADER" ]]; then
  echo "UPSTREAM_REAL_IP_HEADER defaulting to X-Forwarded-For"
  export UPSTREAM_REAL_IP_HEADER=X-Forwarded-For
fi

if [[ -z "$UPSTREAM_REAL_IP_RECURSIVE" ]]; then
  echo "UPSTREAM_REAL_IP_RECURSIVE defaulting to off"
  export UPSTREAM_REAL_IP_RECURSIVE=off
fi

if [[ -z "$FRAPPE_SITE_NAME_HEADER" ]]; then
  # shellcheck disable=SC2016
  echo 'FRAPPE_SITE_NAME_HEADER defaulting to $host'
  # shellcheck disable=SC2016
  export FRAPPE_SITE_NAME_HEADER='$host'
fi

if [[ -z "$PROXY_READ_TIMEOUT" ]]; then
  echo "PROXY_READ_TIMEOUT defaulting to 120"
  export PROXY_READ_TIMEOUT=120
fi

if [[ -z "$CLIENT_MAX_BODY_SIZE" ]]; then
  echo "CLIENT_MAX_BODY_SIZE defaulting to 50m"
  export CLIENT_MAX_BODY_SIZE=50m
fi

# Generate nginx config with all required variables
# shellcheck disable=SC2016
envsubst '${BACKEND}
  ${SOCKETIO}
  ${UPSTREAM_REAL_IP_ADDRESS}
  ${UPSTREAM_REAL_IP_HEADER}
  ${UPSTREAM_REAL_IP_RECURSIVE}
  ${FRAPPE_SITE_NAME_HEADER}
  ${PROXY_READ_TIMEOUT}
  ${CLIENT_MAX_BODY_SIZE}
  ${FRONTEND_ID}' \
  </templates/nginx/frappe.conf.template >/etc/nginx/conf.d/frappe.conf

echo "Starting nginx with Frontend ID: $FRONTEND_ID"
nginx -g 'daemon off;'
