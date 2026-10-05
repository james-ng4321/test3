locals {
  virtual_network_subnets = flatten([
    for virtual_network_name, virtual_network in var.virtual_networks : [
      for subnet_name, subnet in virtual_network.subnets : {
        resource_group_name  = virtual_network.resource_group_name
        virtual_network_name = virtual_network.name
        location             = virtual_network.location
        subnet               = subnet
      }
    ]
  ])
}