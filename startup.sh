#!/bin/bash

cd ~/Desktop
curl -sSL http://bit.ly/2ysbOFE | bash -s 1.4.0
sleep 10
cd ./fabric-samples
git clone https://github.com/kenmyatt-bta/startFiles.git
sleep 10
cd startFiles
mkdir config
wget https://s3.us-east-2.amazonaws.com/lfx-start1/bootstrap.sh
chmod u+x ./bootstrap.sh
chmod u+x start.sh teardown.sh stop.sh
./bootstrap.sh

sleep 30s

rm ./bootstrap.sh ./startup.sh
rm -- "$0"