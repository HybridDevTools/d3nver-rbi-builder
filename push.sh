#!/bin/bash

BUILDFOLDER=$1
CHANNEL=$2

# Amazon S3 storage
aws s3 sync --delete --acl public-read $BUILDFOLDER s3://s3.d3nver.io/rbi/$CHANNEL

# Rsync copy to remote SSH folder
#rsync -avh --progress $BUILDFOLDER <user>@<host>:/<path>/$CHANNEL
