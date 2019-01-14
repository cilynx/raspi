# raspi
Raspberry Pi scripts for various projects

## init_sdcard.sh

This script pulls down the latest Raspbian, enables SSH, sets the hostname, optionally sets up wpa_supplicant.conf, and writes the image to the sdcard.  I use it for preparing Pis for cluster duty as follows:
```
./init_sdcard.sh -d /dev/sdb -e clusternet clusterpi{00..10}
```
This will prompt for the wifi password once and then prompt each time you need to switch the sdcard.  Everything else is automagic.  If you don't want to configure wifi, just leave off the `-e` flag.

## water_the_plants.py

A simple polling app that measures soil moisture content using a [ubiquitous soil sensor](http://amzn.to/1PvM0Lf).  The cool part is that it only powers up the sensor when actively polling, so you save power and the sensor should be slower to corrode since it's not generally acting as an electrode.  If you care about power efficiency and you don't care about logging or remote control, you might be better off using a [purpose built board](http://amzn.to/1UBTgE4) as they're super cheap and much less power hungry than the Pi.
