#!/usr/bin/python -u

import RPi.GPIO as GPIO, time 

# How often to check the soil moisture when it's dry (the water is on)
dry_poll = 1 # seconds

# How often to check the soil moisture when it's wet (the water is off)
wet_poll = 15*60 # seconds

# Count like a grown-up
GPIO.setmode(GPIO.BCM)

# GPIO 17 is our digital sensor input
GPIO.setup(17, GPIO.IN)

# GPIO 18 is used to power the digital sensor board when polling
# This is generally a really bad idea, but this is a very low power
# board and it works well for me anyway.
GPIO.setup(18, GPIO.OUT)

water = 0

try:
    while True:
        GPIO.output(18, GPIO.HIGH)
        time.sleep(.1) # Wait for digital sensor to settle
        if GPIO.input(17):
            print ','.join((time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "Dry"))
            if not water:
                print ','.join((time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "Turn on the water!"))
                water = 1
        else:
            print ','.join((time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "Wet"))
            if water:
                print ','.join((time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()), "Turn off the water!"))
                water = 0
        GPIO.output(18, GPIO.LOW)
        if water:
            time.sleep(dry_poll)
        else:
            time.sleep(wet_poll)
except KeyboardInterrupt:
    GPIO.cleanup()
