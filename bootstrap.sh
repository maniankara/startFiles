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
configtxgen -profile OneOrgChannel -asOrg Org1MSP -outputAnchorPeersUpdate ./config/anchorUpdate.tx -channelID $CHANNEL_NAME
# re-create cli container
docker-compose stop cli
docker-compose up -d cli
# Update anchor peer from peer0 -> peer1
docker exec cli peer channel update -c $CHANNEL_NAME -f /etc/hyperledger/configtx/anchorUpdate.tx -o orderer.example.com:7050
