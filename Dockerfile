# Use specific version for reproducible builds
FROM python:3.11.9-alpine3.19

# Set metadata with OCI labels
LABEL org.opencontainers.image.title="RTL_433 MQTT Home Assistant Bridge" \
      org.opencontainers.image.description="Auto-discovery bridge for rtl_433 devices in Home Assistant via MQTT" \
      org.opencontainers.image.version="1.0" \
      org.opencontainers.image.authors="rtl_433 community" \
      org.opencontainers.image.url="https://github.com/merbanan/rtl_433" \
      org.opencontainers.image.source="https://raw.githubusercontent.com/merbanan/rtl_433/refs/heads/master/examples/rtl_433_mqtt_hass.py" \
      org.opencontainers.image.licenses="GPL-2.0"

# Set working directory
WORKDIR /app

# Install system dependencies for downloading and Python packages
RUN apk add --no-cache \
    curl

# Install system dependencies for downloading and Python packages
RUN apk add --no-cache \
    curl \
    tzdata \
    ca-certificates \
    && update-ca-certificates

# Create app directory structure
RUN mkdir -p /app /app/config /app/logs

# Install Python dependencies with specific versions for reproducibility
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip==24.0 \
    && pip install --no-cache-dir -r /tmp/requirements.txt \
    && rm /tmp/requirements.txt

# Download the latest version of the script from GitHub with retry logic
RUN for i in 1 2 3; do \
        curl -f -o /app/rtl_433_mqtt_hass.py \
        https://raw.githubusercontent.com/merbanan/rtl_433/refs/heads/master/examples/rtl_433_mqtt_hass.py \
        && break || sleep 5; \
    done \
    && chmod +x /app/rtl_433_mqtt_hass.py

# Create startup script that converts environment variables to command line arguments
RUN sh -c "cat > /app/start.sh << 'EOF'"
#!/bin/sh
set -e

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting RTL_433 MQTT Home Assistant Bridge..."

# Validate required environment variables
if [ -z "$MQTT_HOST" ]; then
    log "ERROR: MQTT_HOST environment variable is required"
    exit 1
fi

# Build command line arguments from environment variables
ARGS=""

# Boolean flags
[ "$DEBUG" = "true" ] && ARGS="$ARGS --debug"
[ "$QUIET" = "true" ] && ARGS="$ARGS --quiet"
[ "$RETAIN" = "true" ] && ARGS="$ARGS --retain"
[ "$FORCE_UPDATE" = "true" ] && ARGS="$ARGS --force_update"

# String arguments with validation
[ -n "$MQTT_USERNAME" ] && ARGS="$ARGS --user '$MQTT_USERNAME'"
[ -n "$MQTT_PASSWORD" ] && ARGS="$ARGS --password '$MQTT_PASSWORD'"
[ -n "$MQTT_HOST" ] && ARGS="$ARGS --host '$MQTT_HOST'"
[ -n "$MQTT_PORT" ] && ARGS="$ARGS --port $MQTT_PORT"
[ -n "$MQTT_CA_CERT" ] && ARGS="$ARGS --ca_cert '$MQTT_CA_CERT'"
[ -n "$MQTT_CERT" ] && ARGS="$ARGS --cert '$MQTT_CERT'"
[ -n "$MQTT_KEY" ] && ARGS="$ARGS --key '$MQTT_KEY'"
[ -n "$RTL_TOPIC" ] && ARGS="$ARGS --rtl-topic '$RTL_TOPIC'"
[ -n "$DISCOVERY_PREFIX" ] && ARGS="$ARGS --discovery-prefix '$DISCOVERY_PREFIX'"
[ -n "$DEVICE_TOPIC_SUFFIX" ] && ARGS="$ARGS --device-topic_suffix '$DEVICE_TOPIC_SUFFIX'"
[ -n "$DISCOVERY_INTERVAL" ] && ARGS="$ARGS --interval $DISCOVERY_INTERVAL"
[ -n "$EXPIRE_AFTER" ] && ARGS="$ARGS --expire-after $EXPIRE_AFTER"
[ -n "$DEVICE_IDS" ] && ARGS="$ARGS --ids $DEVICE_IDS"

log "Configuration:"
log "  MQTT Host: $MQTT_HOST:$MQTT_PORT"
log "  RTL Topic: $RTL_TOPIC"
log "  Discovery Prefix: $DISCOVERY_PREFIX"
log "  Discovery Interval: ${DISCOVERY_INTERVAL}s"
[ -n "$DEVICE_IDS" ] && log "  Device IDs Filter: $DEVICE_IDS"
log "Starting with args: $ARGS"

# Handle shutdown gracefully
trap 'log "Shutting down..."; exit 0' TERM INT

# Execute the Python script with built arguments
eval "exec python /app/rtl_433_mqtt_hass.py $ARGS"
EOF

# Make the startup script executable
RUN chmod +x /app/start.sh

# Create a non-root user for security
RUN addgroup -g 1000 rtl433 && \
    adduser -D -s /bin/sh -u 1000 -G rtl433 rtl433

# Change ownership of the app directory
RUN chown -R rtl433:rtl433 /app

# Switch to non-root user
USER rtl433

# Set environment variables with defaults for all parser arguments
ENV DEBUG=false \
    QUIET=false \
    MQTT_USERNAME="" \
    MQTT_PASSWORD="" \
    MQTT_HOST="127.0.0.1" \
    MQTT_PORT=1883 \
    MQTT_CA_CERT="" \
    MQTT_CERT="" \
    MQTT_KEY="" \
    RETAIN=false \
    FORCE_UPDATE=false \
    RTL_TOPIC="rtl_433/+/events" \
    DISCOVERY_PREFIX="homeassistant" \
    DEVICE_TOPIC_SUFFIX="devices[/type][/model][/subtype][/channel][/id]" \
    DISCOVERY_INTERVAL=600 \
    EXPIRE_AFTER="" \
    DEVICE_IDS="" \
    TZ="UTC" \
    PYTHONUNBUFFERED=1 \
    PYTHONIOENCODING=utf-8

# Add common mount points
VOLUME ["/app/config", "/app/logs"]

# Expose no ports (this is a client that connects to MQTT broker)

# Enhanced health check with MQTT connectivity test
HEALTHCHECK --interval=60s --timeout=10s --start-period=30s --retries=3 \
    CMD pgrep -f "rtl_433_mqtt_hass.py" > /dev/null || exit 1

# Use startup script as default command
CMD ["/app/start.sh"]

# Add build info
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF