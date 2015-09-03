#!/bin/bash -ex
source config.cfg

#Dat GPT Table cho cac HDD
parted /dev/sdb mklabel GPT