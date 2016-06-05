# raspi
Raspberry Pi scripts for various projects 

## water_the_plants.py

A simple polling app that measures soil moisture content using a [ubiquitous soil sensor](http://amzn.to/1PvM0Lf).  The cool part is that it only powers up the sensor when actively polling, so you save power and the sensor should be slower to corrode since it's not generally acting as an electrode.  If you care about power efficiency and you don't care about logging or remote control, you might be better off using a [purpose built board](http://amzn.to/1UBTgE4) as they're super cheap and much less power hungry than the Pi.
