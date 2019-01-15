# raspi
Raspberry Pi scripts for various projects

## init_sdcard.sh

This script pulls down the latest Raspbian, enables SSH, sets the hostname, optionally sets up wpa_supplicant.conf, and writes the image to the sdcard.  I use it for preparing Pis for cluster duty as follows:
```
./init_sdcard.sh -d /dev/sdb -e clusternet clusterpi{00..10}
```
This will prompt for the wifi password once and then prompt each time you need to switch the sdcard.  Everything else is automagic.  If you don't want to configure wifi, just leave off the `-e` flag.

## setup_leds.sh

By default, the LEDs on the Pi 3B+ are solid red for power and flashing green for sdcard activity.  There are, however, quite a few things you can trigger on:
```
none rc-feedback kbd-scrolllock kbd-numlock kbd-capslock kbd-kanalock kbd-shiftlock kbd-altgrlock kbd-ctrllock kbd-altlock kbd-shiftllock kbd-shiftrlock kbd-ctrlllock kbd-ctrlrlock timer oneshot heartbeat backlight gpio [cpu] cpu0 cpu1 cpu2 cpu3 default-on input panic mmc1 mmc0 rfkill-any rfkill0 rfkill1
```
For reasons I don't fully understand, the red LED cannot be controlled as granularly as the green one.  Basically red is on or off while green has variable brightness.  To trigger the green activity LED on cpu utilization and the red "power" LED on sdcard activity for my cluster nodes:
```
./setup_leds.sh -g cpu -r mmc0 clusterpi{00.10}
```

## water_the_plants.py

A simple polling app that measures soil moisture content using a [ubiquitous soil sensor](http://amzn.to/1PvM0Lf).  The cool part is that it only powers up the sensor when actively polling, so you save power and the sensor should be slower to corrode since it's not generally acting as an electrode.  If you care about power efficiency and you don't care about logging or remote control, you might be better off using a [purpose built board](http://amzn.to/1UBTgE4) as they're super cheap and much less power hungry than the Pi.
