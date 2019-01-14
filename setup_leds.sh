#!/bin/bash

USER=pi

while getopts ":r:g:" opt; do
   case ${opt} in
      r )
	 RED_TRIGGER=$OPTARG
	 ;;
      g)
	 GREEN_TRIGGER=$OPTARG
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

if [ -z "$RED_TRIGGER" ] && [ -z "$GREEN_TRIGGER" ]; then
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
   if [ -n "$RED_TRIGGER" ]; then
      echo "($HOST): Triggering Red LED with $RED_TRIGGER..."
      ssh "$USER@$HOST" "echo $RED_TRIGGER | sudo tee /sys/class/leds/led1/trigger"
   fi
   if [ -n "$GREEN_TRIGGER" ]; then
      echo "($HOST): Triggering Activity LED with $GREEN_TRIGGER..."
      ssh "$USER@$HOST" "echo $GREEN_TRIGGER | sudo tee /sys/class/leds/led0/trigger"
   fi
done

echo
