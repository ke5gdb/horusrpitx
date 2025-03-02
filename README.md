# Horus Binary Telemetry Transmitter

Transmit Horus Binary v2 using the GPCLK function of the Raspberry Pi. This has been developed for Raspberry Pi OS, version Bookworm.

## How does it work?

The Raspberry Pi Broadcom-based SoC can generate clock signals from near 0 Hz through a large portion of the UHF spectrum. By modulating this clock signal with [librpitx](https://github.com/F5OEO/librpitx), it is possible to transmit Horus Binary v2 using a GPIO pin on a Raspberry Pi. 

The clock signal generated is a square wave, so moderate filtering should be used before routing the signal to an antenna.

## Supported Hardware

System-on-Chip | Raspbery Pi | RPi TX  Supported
------|------|------
BCM2835 | Model 1 A, A+, B, B+, Zero (W) | :grey_question:
BCM2836 | Model 2 B | :grey_question:
BCM2837 | Model 3 B, CM3 (some 2 B),  | :heavy_check_mark:
BCM2837B0 | Model 3 A+, B+, CM3+ | :heavy_check_mark:
BCM2711 | Model 4 B, CM4, Pi 400 | :heavy_check_mark:
BCM2712 | Model 5 B, CM5, Pi 500 | :x:
RP3A0 | Model Zero 2W | :heavy_check_mark:

## Installation - Docker

The recommended method to use this utility is with Docker. 

### Install Docker

If Docker is not installed, follow these directions:

```console
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

sudo usermod -aG docker $(whoami)

sudo reboot
```

### Test Mode

To generate sample packets to test receivers and decoders, a test mode has been written. This mode does not interface to a GPS, but allows you to set certain parameters via command line arguments.

|Argument|Default|Description|
|-|-|-|
|MODE|TEST|Configure container for test mode|
|ID|256|Horus Binary ID. Will not be uploaded if `256` (useful for testing)| 
|FREQ|434.200|Frequency in MHz|
|LAT|0.0|Latitude in degrees north|
|LON|0.0|Longitude in degrees west|
|ALT|0|Altitude in meters|
|SATS|3|Satellites visible -- must be greater than 0 for position to be evaluated|
|VERBOSE|0|Enable verbose mode (`1`) in container|

```console
docker run \
  --name horusrpitx \
  --privileged \
  --device /dev/mem \
  -e MODE=TEST \
  -e ID=256 \
  -e FREQ=434.200 \
  -e LAT=0.0 \
  -e LON=0.0 \
  -e ALT=0 \
  -e SATS=3 \
  ghcr.io/ke5gdb/horusrpitx:testing
```

### GPS Mode

This mode can accept input from a u-blox GPS and transmit position packets from the u-blox GPS input.

|Argument|Default|Description|
|-|-|-|
|device|/dev/ttyACM0|Serial port for GPS|
|MODE|TEST|Configure container for test mode|
|ID|256|Horus Binary ID. Will not be uploaded if `256` (useful for testing)| 
|FREQ|434.200|Frequency in MHz|


```console
docker run \
  --name horusrpitx \
  --privileged \
  --device /dev/mem \
  --device "/dev/ttyACM0:/dev/ttyUSB0" \
  -e MODE=GPS \
  -e ID=256 \
  -e FREQ=434.200 \
  ghcr.io/ke5gdb/horusrpitx:testing
```

### Additional Commands

To start TEST mode or GPS mode on boot, add the following arguments to the Docker commands:

```console
--restart always
--daemon
```

To stop the container, use:

```console 
docker stop horusrpitx
```

To update the container, use:

```console
docker stop horusrpitx
docker rm horusrpitx
docker pull ghcr.io/ke5gdb/horusrpitx:testing
```
and run the container using the appropriate `docker run` command from above.

## Installation - Native Install

### Native Install

Install required libraries and utilities via `apt`:

```console
sudo apt update
sudo apt install --no-install-recommends git libraspberrypi-dev python3-venv python3-pip cmake
```

Install [librpitx](https://github.com/F5OEO/librpitx) with the following commands: 

```console
git clone https://github.com/F5OEO/librpitx.git
cd librpitx/src/
make
sudo make install
cd ~
```

Install [horusdemodlib](https://github.com/projecthorus/horusdemodlib) with the following commands. The build process is to install `libhorus.so`. Further down in these instructions we will use `pip` to install the complemetary Python library to encode packets. Both are needed. 

```console
git clone https://github.com/projecthorus/horusdemodlib.git
cd horusdemodlib && mkdir build && cd build
cmake ..
make
sudo make install
sudo ldconfig
cd ~
```

Build horusrpitx:

```console
git clone https://github.com/projecthorus/horusrpitx.git
cd horusrpitx
python -m venv venv
. venv/bin/activate
pip install -r requirements.txt
cd mod
make
cd ..
```

## Transmitting Sample Packets

In some cases it may be useful to generate sample packets to test a receiver and demodulation software, but without the use of a GPS. 

All of the arguments shown below are optional. They are shown with their default values. 

```console
sudo venv/bin/python PacketTX.py --frequency 434.2 --id 256 --lat 0 --lon 0 --alt 0 --sats 3 --verbose
```
NOTE: `sudo` is required for RPiTX to function. 

## Transmitting Position Packets

To transmit position packets, a U-Blox GPS is required. When connected via USB, the default UART for the U-Blox GPS is `/dev/ttyACM0`. 

```console
sudo venv/bin/python tx_gps.py 256 --frequency 434.2 --gps /dev/ttyACM0
```

## Enable Transmit on Boot

Enabling the horusrpitx transmitter on boot can be accomplished with a systemd unit file. Use these commands to copy the sample systemd unit file to the proper directory. Be sure to update the environment variables for your intended payload ID and transmit frequency.

```console
sudo cp tx_horus.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now tx_horus.service
```

If you need to update the variables in the systemd unit file, be sure to run `sudo systemctl daemon-reload` to commit the updated unit file.
