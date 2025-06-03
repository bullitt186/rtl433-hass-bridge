# RTL_433 MQTT Home Assistant Bridge

A Docker container that bridges RTL_433 radio frequency data to Home Assistant via MQTT with automatic device discovery.

## Overview

This bridge listens to RTL_433 MQTT messages and automatically creates Home Assistant device configurations for supported sensors. It eliminates the need for manual sensor configuration by using Home Assistant's MQTT discovery feature.

## Features

- 🔄 Automatic Home Assistant device discovery
- 🐳 Docker containerized for easy deployment
- 🔒 Security-focused with non-root user and read-only filesystem
- 📊 Configurable logging and monitoring
- 🌐 Support for external MQTT brokers
- 🔧 Flexible configuration via environment variables
- 📡 Support for TLS/SSL connections

## Quick Start

### Using Docker Compose (Recommended)

1. Create a `.env` file with your MQTT broker details:
```env
MQTT_HOST=your-mqtt-broker.local
MQTT_USERNAME=your-username
MQTT_PASSWORD=your-password
```

2. Start the container:
```bash
docker compose up -d
```

### Using Docker Run

```bash
docker run -d \
  --name rtl433-hass-bridge \
  --restart unless-stopped \
  -e MQTT_HOST=your-mqtt-broker.local \
  -e MQTT_USERNAME=your-username \
  -e MQTT_PASSWORD=your-password \
  bullitt168/rtl433-hass-bridge:latest
```

## Configuration

### Required Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `MQTT_HOST` | MQTT broker hostname/IP | `192.168.1.100` |

### Optional Environment Variables

#### MQTT Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `MQTT_PORT` | `1883` | MQTT broker port |
| `MQTT_USERNAME` | | MQTT username |
| `MQTT_PASSWORD` | | MQTT password |
| `MQTT_CA_CERT` | | Path to CA certificate for TLS |
| `MQTT_CERT` | | Path to client certificate for TLS |
| `MQTT_KEY` | | Path to client private key for TLS |

#### RTL_433 Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `RTL_TOPIC` | `rtl_433/+/events` | MQTT topic to subscribe to for RTL_433 data |
| `DEVICE_TOPIC_SUFFIX` | `devices[/type][/model][/subtype][/channel][/id]` | Topic structure for device data |

#### Home Assistant Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `DISCOVERY_PREFIX` | `homeassistant` | Home Assistant MQTT discovery prefix |
| `DISCOVERY_INTERVAL` | `600` | Device discovery interval in seconds |
| `EXPIRE_AFTER` | | Device expiration time in seconds |
| `FORCE_UPDATE` | `false` | Force entity updates even if value unchanged |
| `RETAIN` | `true` | Retain MQTT discovery messages |

#### Filtering and Logging
| Variable | Default | Description |
|----------|---------|-------------|
| `DEVICE_IDS` | | Space-separated list of device IDs to include |
| `DEBUG` | `false` | Enable debug logging |
| `QUIET` | `false` | Reduce log output |
| `TZ` | `UTC` | Container timezone |

## TLS/SSL Configuration

For secure MQTT connections, mount your certificates and configure the paths:

```yaml
services:
  rtl433-bridge:
    image: bullitt168/rtl433-hass-bridge:latest
    volumes:
      - ./certs:/certs:ro
    environment:
      - MQTT_CA_CERT=/certs/ca.crt
      - MQTT_CERT=/certs/client.crt
      - MQTT_KEY=/certs/client.key
```

## Building from Source

### Prerequisites
- Docker
- Git

### Build Commands

```bash
# Build locally
./build.sh

# Build and push to Docker Hub
./build.sh -p --dockerhub -n yourusername/rtl433-hass-bridge

# Build with custom tag
./build.sh -t v1.0.0
```

### Build Options
| Flag | Description |
|------|-------------|
| `-n, --name` | Docker image name |
| `-t, --tag` | Docker image tag |
| `-p, --push` | Push to registry after build |
| `--dockerhub` | Use Docker Hub registry |
| `-r, --registry` | Custom registry URL |

## Health Monitoring

The container includes a health check that monitors the Python process:
- **Interval**: 60 seconds
- **Timeout**: 10 seconds
- **Retries**: 3
- **Start Period**: 30 seconds

## Logs

Container logs are available via Docker:
```bash
docker logs rtl433-hass-bridge
```

Persistent logs can be accessed via the mounted volume:
```bash
docker exec rtl433-hass-bridge ls /app/logs
```

## Troubleshooting

### Common Issues

1. **Container exits immediately**
   - Check that `MQTT_HOST` is set
   - Verify MQTT broker is accessible
   - Check container logs for error messages

2. **No devices appearing in Home Assistant**
   - Verify RTL_433 is publishing to the correct MQTT topic
   - Check Home Assistant MQTT integration is configured
   - Ensure discovery prefix matches Home Assistant configuration

3. **Connection refused**
   - Verify MQTT broker hostname/IP is correct
   - Check firewall settings
   - Ensure MQTT broker is running and accessible

### Debug Mode

Enable debug logging for detailed troubleshooting:
```bash
docker run -e DEBUG=true bullitt168/rtl433-hass-bridge:latest
```

## License

This project is licensed under the GPL-2.0 License - see the original [RTL_433 project](https://github.com/merbanan/rtl_433) for details.

## Credits

Based on the [rtl_433_mqtt_hass.py](https://github.com/merbanan/rtl_433/blob/master/examples/rtl_433_mqtt_hass.py) script from the RTL_433 project.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with your setup
5. Submit a pull request

## Support

- [RTL_433 Documentation](https://github.com/merbanan/rtl_433)
- [Home Assistant MQTT Discovery](https://www.home-assistant.io/docs/mqtt/discovery/)
- [Docker Hub Repository](https://hub.docker.com/r/bullitt168/rtl433-hass-bridge)