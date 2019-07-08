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
# Create crypto certificates for org2
cryptogen extend --config=crypto-config.yaml

# org2 config material
configtxgen -printOrg Org2MSP > ./config/org2.json

# Fetch the latest config, convert to json
docker exec cli peer channel fetch config config_block.pb -o orderer.example.com:7050 -c $CHANNEL_NAME 
docker exec cli bash -c "configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json"

# append the config definition and convert config json and modified config json to pb
docker exec cli bash -c "jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json /etc/hyperledger/configtx/org2.json > modified_config.json"
docker exec cli configtxlator proto_encode --input config.json --type common.Config --output config.pb
docker exec cli configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

# calculate the delta, convert pb to json and wrap it the envelop and convert to pb
docker exec cli configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org2_update.pb
docker exec cli bash -c "configtxlator proto_decode --input org2_update.pb --type common.ConfigUpdate | jq . > org2_update.json"
docker exec cli bash -c 'echo {\"payload\":{\"header\":{\"channel_header\":{\"channel_id\":\"allarewelcome\", \"type\":2}},\"data\":{\"config_update\":$(cat org2_update.json)}}} | jq . > org2_update_in_envelope.json'
docker exec cli configtxlator proto_encode --input org2_update_in_envelope.json --type common.Envelope --output org2_update_in_envelope.pb

# sign and submit the update
docker exec cli peer channel signconfigtx -f org2_update_in_envelope.pb
docker exec cli peer channel update -f org2_update_in_envelope.pb -c $CHANNEL_NAME -o orderer.example.com:7050

# Join the org2 peers to the channel
docker-compose up -d
docker exec cli peer channel fetch 0 allarewelcome.block -o orderer.example.com:7050 -c $CHANNEL_NAME
docker exec -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel join -b allarewelcome.block
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer channel join -b allarewelcome.block

# Upgrade 1.1 -> 2.0 and invoke chaincode in all 4 peers
docker exec cli peer chaincode install -n sacc -v 2.0 -p github.com/sacc
docker exec -e CORE_PEER_ADDRESS=peer1.org1.example.com:7051 cli peer chaincode install -n sacc -v 2.0 -p github.com/sacc
docker exec -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer chaincode install -n sacc -v 2.0 -p github.com/sacc
docker exec -e CORE_PEER_ADDRESS=peer1.org2.example.com:7051 -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp cli peer chaincode install -n sacc -v 2.0 -p github.com/sacc
docker exec cli peer chaincode upgrade -n sacc -v 2.0 -C $CHANNEL_NAME -o orderer.example.com:7050 -c '{"Args":["March", "80"]}' --policy "AND('org1.peer', OR('org2.peer'))"
