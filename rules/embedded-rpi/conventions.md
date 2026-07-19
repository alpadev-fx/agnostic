---
paths:
  - "**/config.txt"
  - "**/*.dts"
  - "**/*.dtbo"
  - "**/gpio*"
---
# Raspberry Pi — Conventions

## Know Your Board
| Model | SoC | Arch | Notes |
|---|---|---|---|
| Pi 5 | BCM2712 | ARM Cortex-A76 (AArch64) | GPIO via RP1 chip — old direct-register code breaks |
| Pi 4 / 400 | BCM2711 | Cortex-A72 (AArch64) | |
| Pi 3 | BCM2837 | Cortex-A53 | |
| Pi Zero 2 W | BCM2710 | Cortex-A53 | Pi 3 family, 512MB |
| Pico / Pico 2 | RP2040 / RP2350 | Cortex-M0+ / M33 | Microcontroller — bare metal / MicroPython, NOT Linux |

- `cat /proc/device-tree/model` to identify at runtime; never hardcode board assumptions

## GPIO — Modern Stack (2024+)
- **`libgpiod` v2 is the standard** (C/C++ and Python bindings). sysfs GPIO (`/sys/class/gpio`) is deprecated/removed
- Python: `gpiozero` for high-level (uses lgpio/pigpio backends), `gpiod` for direct control
- **RPi.GPIO and pigpio are broken on Pi 5** (RP1 chip) — use gpiozero or libgpiod
- Pin numbering: BCM (GPIO#) vs physical header pin — state which in every doc/comment; prefer BCM
- GPIO is 3.3V, NOT 5V-tolerant — level-shift 5V peripherals or kill the pin

```python
from gpiozero import LED, Button
led = LED(17)            # BCM numbering
btn = Button(27, pull_up=True)
btn.when_pressed = led.toggle
```

```c
/* libgpiod v2 */
struct gpiod_chip *chip = gpiod_chip_open("/dev/gpiochip0");
/* request line 17 as output, set value, release — always check returns */
```

## Buses
- Enable in `config.txt` / `raspi-config`: `dtparam=i2c_arm=on`, `dtparam=spi=on`
- I2C: `i2cdetect -y 1` to scan; Python `smbus2`; watch for address conflicts
- SPI: `/dev/spidev0.*`; Python `spidev`; mode + max speed explicit in code
- UART: on Pi 3/4 the good PL011 UART defaults to Bluetooth — `dtoverlay=disable-bt` to reclaim for serial
- 1-Wire (DS18B20 etc.): `dtoverlay=w1-gpio`

## Device Tree
- Overlays in `/boot/firmware/config.txt` (Bookworm+; was `/boot/config.txt`)
- Custom overlay: write `.dts`, compile `dtc -@ -I dts -O dtb`, drop in `/boot/firmware/overlays/`
- Prefer an existing overlay + params over custom DTS

## Deployment Discipline
- Pin OS version in docs (Bookworm vs Bullseye changes paths, Python, libcamera)
- Python: venv per project (`python3 -m venv`) — Bookworm blocks system-pip installs (PEP 668)
- Services via systemd units, not rc.local or cron @reboot:
```ini
[Service]
ExecStart=/home/pi/app/venv/bin/python /home/pi/app/main.py
Restart=on-failure
[Install]
WantedBy=multi-user.target
```
- SD card longevity: log to tmpfs or journald with volatile storage; avoid chatty writes
- Watchdog: `dtparam=watchdog=on` + systemd `RuntimeWatchdogSec` for headless boxes

## Cross-Compilation
- Fast inner loop: build on workstation with `aarch64-linux-gnu-gcc` (or Docker + qemu/binfmt), deploy binary via `rsync`/`scp`
- CMake toolchain file per target; CI builds both host tests and target binary

## Power & Hardware Safety
- Pi 5 wants 5V/5A USB-C PD; undervoltage throttles silently — check `vcgencmd get_throttled`
- Never draw >16mA per GPIO, ~50mA total across pins — transistor/MOSFET for anything real
- Common ground between Pi and every external circuit

## Anti-patterns
- sysfs GPIO in new code
- Polling loops burning CPU where edge events (`when_pressed`, gpiod events) exist
- Running as root for GPIO — add user to `gpio`/`i2c`/`spi` groups
- Testing only on the bench Pi model, deploying to a different one
- `pip install` into system Python on Bookworm
