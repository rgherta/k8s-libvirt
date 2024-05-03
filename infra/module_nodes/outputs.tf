output "net_addr" {
  value = {
    for vm in libvirt_domain.vm : "ips" => vm.network_interface...
  }
}
