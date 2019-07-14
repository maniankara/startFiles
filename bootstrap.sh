#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=allarewelcome

set -ev

docker-compose -f docker-compose.yml up -d peer0.org1.example.com cli

export FABRIC_START_TIMEOUT=5
sleep ${FABRIC_START_TIMEOUT}

# fetch and join a channel
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer0.org1.example.com peer channel fetch 0 allarewelcome.block -o orderer.example.com:7050 -c allarewelcome
docker exec -e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@org1.example.com/msp peer0.org1.example.com peer channel join -b allarewelcome.block

# chaincode query with tls
export cert_base=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin\@org1.example.com/tls
docker exec cli peer channel list --tls --cafile $cert_base/ca.crt --keyfile $cert_base/client.key --certfile $cert_base/client.crt