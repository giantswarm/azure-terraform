resource "azurerm_virtual_machine_scale_set" "workers" {
  location = var.location
  name = "${var.cluster_name}-workers"
  resource_group_name = var.resource_group_name
  upgrade_policy_mode = "Rolling"
  health_probe_id = var.node_health_probe_id
  rolling_upgrade_policy {
    max_batch_instance_percent = 40
    max_unhealthy_instance_percent = 40
    max_unhealthy_upgraded_instance_percent = 40
    pause_time_between_batches = "PT30S"
  }
  network_profile {
    name = "worker-nic-0"
    primary = true
    accelerated_networking = var.enable_accelerated_networking
    ip_forwarding = true
    ip_configuration {
      name = "worker-ipconfig-0"
      primary = true
      subnet_id = var.subnet_id
      load_balancer_backend_address_pool_ids = [
        var.ingress_backend_address_pool_id
      ]
    }
  }
  overprovision = false
  plan {
    name = var.flatcar_linux_channel
    publisher = "kinvolk"
    product = "flatcar-container-linux-free"
  }
  os_profile {
    admin_username = "core"
    computer_name_prefix = "worker-"
    custom_data = base64encode(data.ignition_config.worker_loader.rendered)
  }
  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/core/.ssh/authorized_keys"
      key_data = var.core_ssh_key
    }
  }
  sku {
    name = var.vm_size
    capacity = var.min_worker_count
    tier = "standard"
  }
  storage_profile_image_reference {
    publisher = "kinvolk"
    offer     = "flatcar-container-linux-free"
    sku       = var.flatcar_linux_channel
    version   = var.flatcar_linux_version
  }
  storage_profile_os_disk {
    managed_disk_type = var.os_disk_storage_type
    create_option     = "FromImage"
    caching           = "ReadWrite"
    os_type           = "linux"
  }
  storage_profile_data_disk {
    create_option   = "Empty"
    lun             = 0
    disk_size_gb    = var.docker_disk_size
    managed_disk_type = var.storage_type
  }

  tags = {
    GiantSwarmInstallation       = var.cluster_name
    "cluster-autoscaler-enabled" = "true"
    "cluster-autoscaler-name"    = var.cluster_name
    min                          = var.min_worker_count
    max                          = var.max_worker_count
  }

  timeouts {
    create = "60m"
    delete = "2h"
  }
}
