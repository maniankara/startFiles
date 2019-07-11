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
# clean and start ca container (actually doesnot start ca, but just run sleep)
docker kill ca.example.com
docker rm ca.example.com
docker-compose up -d ca.example.com

# init and run
docker exec ca.example.com fabric-ca-server init -b caServerAdmin:caadminpass
docker exec ca.example.com fabric-ca-server start -b caServerAdmin:caadminpass -p 8080 --cfg.identities.allowremove &
sleep 5

# start intermediate ca server
docker exec ca.example.com fabric-ca-server start -b caServerInterm:cainterpass -u http://caServerAdmin:caadminpass@localhost:8080 -p 3000 --cfg.identities.allowremove &
sleep 5

# Enroll ourself, register and enroll org1admin
docker exec ca.example.com fabric-ca-client enroll -u http://caServerAdmin:caadminpass@localhost:8080
docker exec ca.example.com fabric-ca-client register --id.name org1admin --id.secret org1adminpass --id.type admin --id.affiliation org1 --id.attrs 'hf.Revoker=true,admin=true:ecert,hf.Registrar.Roles=peer,hf.GenCRL=true' -u http://localhost:8080
docker exec ca.example.com fabric-ca-client enroll -u http://org1admin:org1adminpass@localhost:8080

# Register and enroll peerJohn and peerSam as peers
docker exec ca.example.com fabric-ca-client register --id.name peerJohn --id.secret peerjohnpass --id.affiliation org1 --id.type peer -u http://localhost:8080
docker exec ca.example.com fabric-ca-client enroll -u http://peerJohn:peerjohnpass@localhost:8080
docker exec ca.example.com fabric-ca-client enroll -u http://org1admin:org1adminpass@localhost:8080 # hack to set to admin (local msg: 'user' is not a registrar)
docker exec ca.example.com fabric-ca-client register --id.name peerSam --id.secret peersampass --id.affiliation org1 --id.type peer -u http://localhost:8080
docker exec ca.example.com fabric-ca-client enroll -u http://peerSam:peersampass@localhost:8080

# verify
docker exec ca.example.com fabric-ca-client enroll -u http://caServerAdmin:caadminpass@localhost:8080

# query
docker exec ca.example.com fabric-ca-client identity list *

# revoke
docker exec ca.example.com fabric-ca-client revoke -e peerSam -r unspecified -u http://localhost:8080
docker exec ca.example.com fabric-ca-client gencrl
docker exec ca.example.com fabric-ca-client certificate list --revocation 2018-01-01::2020-01-30
docker exec ca.example.com fabric-ca-client identity remove peerJohn