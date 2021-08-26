[kube-master:children]
master

[kube-node:children]
node
storage

[k8s-cluster:children]
%{ for group, members in groups ~}
${group}
%{ endfor ~}
calico-rr

%{ for group, members in groups ~}
[${group}]
%{ for member in members ~}
${member.name} ansible_host=${member.ip} %{ if member.etcd != null }etcd_member_name=${member.etcd}%{ endif }
%{ endfor }
%{ endfor ~}
[etcd:children]
kube-master

[calico-rr]
[storage]
