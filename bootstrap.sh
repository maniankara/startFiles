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
docker-compose up -d ca.example.com