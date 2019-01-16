#!/bin/bash

USER=pi

while getopts ":r:g:p" opt; do
   case ${opt} in
      p )
	 PWR_CONF="dtparam=pwr_led_trigger"
	 ACT_CONF="dtparam=act_led_trigger"
	 ;;
      r )
	 PWR_TRIGGER=$OPTARG
	 ;;
      g)
	 ACT_TRIGGER=$OPTARG
	 ;;
      \?)
	 echo "Invalid option: -$OPTARG" 1>&2
	 exit
	 ;;
      : )
	 echo "Invalid option: -$OPTARG requires an argument" 1>&2
	 exit
	 ;;
   esac
done

shift $((OPTIND-1))
HOSTS=("$@")

if [ -z "${HOSTS[0]}" ]; then
   echo
   echo "Usage: $0 -g [green_trigger] -r [red_trigger] hostname(s)"
   echo
   exit
fi

if [ -z "$PWR_TRIGGER" ] && [ -z "$ACT_TRIGGER" ]; then
   echo
   echo "Trigger options:"
   echo
   ssh "$USER@${HOSTS[0]}" "cat /sys/class/leds/led0/trigger"
   echo
   echo "Usage: $0 -g [green_trigger] -r [red_trigger] hostname(s)"
   echo
   exit
fi

for HOST in "${HOSTS[@]}"; do
   echo
   if [ -n "$PWR_TRIGGER" ]; then
      echo "($HOST): Triggering power LED with $PWR_TRIGGER..."
      ssh "$USER@$HOST" "echo $PWR_TRIGGER | sudo tee /sys/class/leds/led1/trigger"
      if [ -n "$PWR_CONF" ]; then
	 echo "Persisting power LED configuration..."
	 ssh "$USER@$HOST" "grep -qF $PWR_CONF /boot/config.txt || echo $PWR_CONF=$PWR_TRIGGER | sudo tee --append /boot/config.txt"
      fi
   fi
   if [ -n "$ACT_TRIGGER" ]; then
      echo "($HOST): Triggering activity LED with $ACT_TRIGGER..."
      ssh "$USER@$HOST" "echo $ACT_TRIGGER | sudo tee /sys/class/leds/led0/trigger"
      if [ -n "$ACT_CONF" ]; then
	 echo "Persisting activity LED configuration..."
	 ssh "$USER@$HOST" "grep -qF $ACT_CONF /boot/config.txt || echo $ACT_CONF=$ACT_TRIGGER | sudo tee --append /boot/config.txt"
      fi
   fi
done

echo
