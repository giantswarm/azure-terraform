alias etcdctl="ETCDCTL_API=3 \
      ETCDCTL_ENDPOINTS=https://127.0.0.1:2379 \
      ETCDCTL_CACERT=/etc/kubernetes/ssl/etcd/client-ca.pem \
      ETCDCTL_CERT=/etc/kubernetes/ssl/etcd/client-crt.pem \
      ETCDCTL_KEY=/etc/kubernetes/ssl/etcd/client-key.pem \
      etcdctl"
