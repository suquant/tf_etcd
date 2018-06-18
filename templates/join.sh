#/bin/sh

set -e

dropin_dir="/etc/systemd/system/etcd.service.d"
join_env_file="$dropin_dir/join.env"

# Sequential join
attemps=30
until \
  [ $attemps -le 0 ] || \
  [ $(timeout 5 etcdctl --endpoints "${primary_client_url}" member list | wc -l) -ge ${sequence_number} ]; do
    echo 'wait etcd cluster...'
    sleep 5
    attemps=$((attemps-1))
done

mkdir -p $dropin_dir
echo "[Service]\nEnvironmentFile=$join_env_file" > $dropin_dir/10-join.conf

# Wait till member join to cluster
attemps=30
until \
    [ $attemps -le 0 ] || \
    etcdctl --endpoints "${primary_client_url}" member add "${hostname}" "${peer_url}" > /tmp/etcd-join.log; do
    echo 'wait member add to cluster...'
    sleep 5
    attemps=$((attemps-1))
done

cat /tmp/etcd-join.log | tail -n 2 >> $join_env_file

systemctl is-enabled etcd.service || systemctl enable etcd.service
systemctl daemon-reload
systemctl start etcd.service