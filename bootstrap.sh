#!/bin/sh
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
export PATH=$GOPATH/src/github.com/hyperledger/fabric/build/bin:${PWD}/../bin:${PWD}:$PATH
export FABRIC_CFG_PATH=${PWD}
CHANNEL_NAME=allarewelcome
COMPOSE_PROJECT_NAME=startfiles

set -ev
# Install chaincode on peer0.org1.example.com and peer1.org1.example.com.
docker exec cli peer chaincode install -n sacc -v 1.0 -p github.com/sacc
docker exec -e "CORE_PEER_ADDRESS=peer1.org1.example.com:7051" cli peer chaincode install -n sacc -v 1.0 -p github.com/sacc
# Instantiate chaincode from peer0 (anchor)
docker exec cli peer chaincode instantiate -n sacc -v 1.0 -C allarewelcome -c '{"Args":["Match", "50"]}' --policy "AND('org1.peer', OR ('org1.member'))"