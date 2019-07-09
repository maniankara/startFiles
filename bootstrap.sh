#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
COMPOSE_PROJECT_NAME=startfiles
CHANNEL_NAME=allarewelcome

set -ev
# start kakfa and zookeeper
docker-compose up -d kafka0.example.com kafka1.example.com zoo0.example.com zoo1.example.com zoo2.example.com
docker-compose up -d ca.example.com orderer.example.com peer0.org1.example.com peer1.org1.example.com peer0.org2.example.com peer1.org2.example.com cli

# Re-join CHANNEL_NAME to all peers
docker exec cli peer channel fetch 0 allarewelcome.block -o orderer.example.com:7050 -c $CHANNEL_NAME
docker exec cli peer channel join -b allarewelcome.block
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 cli peer channel join -b allarewelcome.block
docker exec -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel join -b allarewelcome.block
docker exec -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel join -b allarewelcome.block