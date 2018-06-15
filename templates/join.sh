#!/bin/sh

set -e

client_urls="${join_clients}"

[ -z "$client_urls" ] || (
    exec etcdctl -C "$client_urls" member add "${hostname}" "${urls}"
)
