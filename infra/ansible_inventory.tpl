[control_plane]
%{ for index, ip in ips["control_plane"] ~}
vm-cp-${index} ansible_host=${ip} ansible_user=maintainer ansible_ssh_private_key_file=keys/private_key_cp.pem
%{ endfor ~}

[data_plane]
%{ for index, ip in ips["data_plane"] ~}
vm-dp-${index} ansible_host=${ip} ansible_user=maintainer ansible_ssh_private_key_file=keys/private_key_dp.pem
%{ endfor ~}
