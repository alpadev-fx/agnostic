---
paths:
  - "**/armbian*"
  - "**/orangepi*"
  - "**/*.fex"
---
# Orange Pi — Conventions

## Know Your Board (SoC decides everything)
| Family | SoC | Arch | Notes |
|---|---|---|---|
| OPi 5 / 5 Plus / 5 Pro | Rockchip RK3588(S) | Cortex-A76+A55 | NPU 6 TOPS, best mainline support of the lot |
| OPi 3B | Rockchip RK3566 | Cortex-A55 | |
| OPi Zero 2W / Zero 3 | Allwinner H618 | Cortex-A53 | |
| OPi PC / Zero (legacy) | Allwinner H3/H2+ | Cortex-A7 (32-bit) | |

- Identify at runtime: `cat /proc/device-tree/model`, `cat /etc/armbian-release`
- Rockchip ≠ Allwinner ≠ Broadcom: pin maps, overlays, boot chain all differ. Raspberry Pi tutorials do NOT transfer 1:1

## OS Choice (first decision, biggest lever)
- **Armbian** — community, best maintained, prefer it for anything long-running
- Vendor "Orange Pi OS" images — newest hardware enabled first, weakest updates
- Check kernel status per board: mainline vs vendor BSP kernel changes what works (NPU, VPU, panfrost GPU)
- Document exact image + kernel version in project README — reproducibility on SBCs is fragile

## GPIO
- **`libgpiod` v2** — the portable answer; works across Allwinner and Rockchip
- `wiringOP` / `wiringOP-Python` — vendor fork of WiringPi; convenient but board-specific pin tables
- `OPi.GPIO` — RPi.GPIO-compatible Python shim for Allwinner boards (legacy)
- Pin numbering chaos is the #1 bug source: physical header ≠ GPIO chip/line ≠ wiringOP number.
  Map with `gpioinfo` (libgpiod) and the board's schematic; comment the mapping in code:
```python
# OPi Zero 3: physical pin 7 = PC9 = gpiochip0 line 73
import gpiod
line = gpiod.Chip("gpiochip0").get_line(73)
```
- 3.3V logic, same current limits as any SBC — level-shift 5V gear

## Buses & Overlays
- Armbian: enable overlays in `/boot/armbianEnv.txt`:
```
overlays=i2c1 spi-spidev uart2
param_spidev_spi_bus=1
```
- Vendor images: `orangepi-config` or `/boot/orangePiEnv.txt`
- Verify with `ls /dev/i2c-* /dev/spidev*` after reboot — overlay names differ per SoC
- Allwinner legacy (3.4 kernels) used `.fex` script files — migrate off these images

## Deployment Discipline
- Same rules as any embedded Linux box: systemd services, venv-per-project Python, journald volatile logging, watchdog enabled
- eMMC > SD card for reliability where the board offers it; SPI-NOR boot on some models
- Thermals: RK3588 throttles hard without heatsink — `cat /sys/class/thermal/thermal_zone*/temp` in health checks

## Cross-Compilation
- `aarch64-linux-gnu-gcc` for 64-bit boards, `arm-linux-gnueabihf-gcc` for H3-era 32-bit
- Armbian build framework can produce full custom images (kernel config, overlays baked in) — use for fleet deployments

## NPU / Media (RK3588 boards)
- NPU via RKNN toolkit (`rknn-toolkit2`) — convert ONNX models, run with `rknnlite`
- Hardware video: mpp/rkmpp with ffmpeg patches; check kernel support before promising performance

## Anti-patterns
- Copy-pasting Raspberry Pi GPIO code and expecting the pinout to hold
- Trusting numbered "GPIO x" from a random tutorial without checking `gpioinfo` for YOUR board rev
- Vendor image + `apt upgrade` blindly — kernel replacement can drop board support; pin kernel packages
- Ignoring PSU quality — half of "random crashes" on Orange Pi are power
- Assuming community support parity with Raspberry Pi — budget debugging time accordingly
