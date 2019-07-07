#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=allarewelcome

# extend crypto material
cryptogen extend --config=./crypto-config.yaml
if [ "$?" -ne 0 ]; then
  echo "Failed to extend crypto material..."
  exit 1
fi

set -ev

# don't rewrite paths for Windows Git Bash users
export MSYS_NO_PATHCONV=1

# clean up and start
docker rm peer1.org1.example.com
docker-compose -f docker-compose.yml up -d peer1.org1.example.com

# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
export FABRIC_START_TIMEOUT=5
#echo ${FABRIC_START_TIMEOUT}
sleep ${FABRIC_START_TIMEOUT}

# Join peer0.org1.example.com to the channel.
#docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer0.org1.example.com peer channel join -b allarewelcome.block
# Join peer1.org1.example.com to the channel.
docker exec peer1.org1.example.com peer channel fetch oldest allarewelcome.block -c allarewelcome -o orderer.example.com:7050
docker exec -e "CORE_PEER_LOCALMSPID=Org1MSP" -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp" peer1.org1.example.com peer channel join -b allarewelcome.block