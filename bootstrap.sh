#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
COMPOSE_PROJECT_NAME=startfiles

set -ev
# Create org1 only channel
configtxgen -profile Org1Channel -outputCreateChannelTx ./config/org1channel.tx -channelID org1channel
docker exec cli peer channel create -f /etc/hyperledger/configtx/org1channel.tx -c org1channel -o orderer.example.com:7050
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp cli peer channel join -b org1channel.block

# Create org2 only channel
configtxgen -profile Org2Channel -outputCreateChannelTx ./config/org2channel.tx -channelID org2channel
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel create -f /etc/hyperledger/configtx/org2channel.tx -c org2channel -o orderer.example.com:7050
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel join -b org2channel.block

# Create org1+org2 channel
configtxgen -profile Org1Org2Channel -outputCreateChannelTx ./config/org1org2channel.tx -channelID org1org2channel
docker exec cli peer channel create -f /etc/hyperledger/configtx/org1org2channel.tx -c org1org2channel -o orderer.example.com:7050
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp cli peer channel join -b org1org2channel.block
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel join -b org1org2channel.block
