#!/bin/bash
for c in nodemanager1 nodemanager2; do
  if docker exec $c which python3 >/dev/null 2>&1; then
    echo "$c: python3 present"
  else
    echo "$c: installing python3"
    docker exec -u root $c bash -c "sed -i 's|deb.debian.org|archive.debian.org|g; s|security.debian.org|archive.debian.org|g; /stretch-updates/d' /etc/apt/sources.list && apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y python3"
  fi
done
