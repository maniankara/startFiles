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
# Upgrade chaincode from 1.0 -> 1.1
docker exec cli peer chaincode install -v 1.1 -n sacc -p github.com/sacc
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 cli peer chaincode install -v 1.1 -n sacc -p github.com/sacc
# Upgrade the instantiation
docker exec cli peer chaincode upgrade -C $CHANNEL_NAME -n sacc -v 1.1 -o orderer.example.com:7050 -c '{"Args":["March", "60"]}' --policy "AND('org1.peer', OR('org1.member'))"
