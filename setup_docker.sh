#!/bin/bash

USER=pi

while getopts ":j:" opt; do
   case ${opt} in
      j )
      MANAGER=$OPTARG
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
   echo "Usage: $0 [-j existing_manager] hostname(s)"
   echo
   exit
fi

PROMPT="All hosts will have their Docker purged and reinstalled from get.docker.com."
JOIN_EXISTING_SWARM=" && "

if [ -n "$MANAGER" ]; then
   PROMPT+="  All hosts will then join $MANAGER's swarm as workers."
else
   MANAGER=${HOSTS[0]}
   shift
   HOSTS=("$@")
   PROMPT+="  Creating a new swarm with $MANAGER as Leader."
   LEADER_IP=$(host $MANAGER | grep "has address" | awk '{print $4}')
   echo "Setting up $MANAGER ($LEADER_IP) as a new swarm Leader..."
   ssh "$USER@$MANAGER" "sudo apt -y purge docker* && curl -sSl https://get.docker.com | sh && sudo usermod -aG docker $USER && docker swarm init --advertise-addr $LEADER_IP && echo \(\`hostname\`\): done"
fi

PROMPT+="  Proceed? "
JOIN_EXISTING_SWARM+="$(ssh $USER@$MANAGER "docker swarm join-token worker" | sed -n 3p) && "
JOIN_EXISTING_SWARM+="echo \(\`hostname\`\): done"

echo
read -p "$PROMPT" -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
   for HOST in "${HOSTS[@]}"; do
      echo
      echo "($HOST): sudo apt -y purge docker* && curl -sSl https://get.docker.com | sh && sudo usermod -aG docker $USER $JOIN_EXISTING_SWARM"
      ssh "$USER@$HOST" "sudo apt -y purge docker* > /dev/null 2>&1 && curl -sSl https://get.docker.com | sh > /dev/null 2>&1 && sudo usermod -aG docker $USER $JOIN_EXISTING_SWARM" &
   done
fi

echo
