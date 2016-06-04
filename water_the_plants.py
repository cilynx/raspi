#!/usr/bin/python

import RPi.GPIO as GPIO, time 

# How often to check the soil moisture? (in seconds)
poll = 1

# How long should it be dry before we turn on the water? (in seconds)
alert = 10 

GPIO.setmode(GPIO.BCM)
GPIO.setup(17, GPIO.IN)
GPIO.setup(18, GPIO.OUT)

count = 0
water = 0

try:
    while True:
        GPIO.output(18, GPIO.HIGH)
        time.sleep(.1)
        if GPIO.input(17):
            print "Dry"
            count += 1
        else:
            print "Wet"
            count = 0
        GPIO.output(18, GPIO.LOW)
        if count > alert / poll:
            if not water:
                print "Turn on the water!"
                water = 1
        else:
            if water:
                print "Turn off the water!"
                water = 0
        time.sleep(poll)
except KeyboardInterrupt:
    GPIO.cleanup()
