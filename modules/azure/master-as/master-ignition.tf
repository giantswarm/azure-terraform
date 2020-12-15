locals {
  timenow = timestamp()
}

# Only necessary, because azurerm_storage_blob requires file as a source.
resource "local_file" "master_ignition" {
  count = var.master_count

  content  = var.user_data[ count.index]
  filename = "${path.cwd}/generated/master-ignition${count.index}.yaml"
}

resource "azurerm_storage_blob" "master_ignition_blob" {
  count = var.master_count

  name = "master-ignition${count.index}-${md5(var.user_data[count.index])}.yaml"

  storage_account_name   = var.storage_acc
  storage_container_name = var.storage_container

  type   = "Block"
  source = "${path.cwd}/generated/master-ignition${count.index}.yaml"
}

# Create temporary credentials to access storage account objects.
data "azurerm_storage_account_sas" "master_sas" {
  connection_string = var.storage_acc_url
  https_only        = true

  # Set TTL to 3 months from execution time.
  start  = local.timenow
  expiry = timeadd(local.timenow, "2160h")

  resource_types {
    service   = false
    container = false
    object    = true
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

data "ignition_config" "master_loader" {
  count = var.master_count

  replace {
    source = "${element(azurerm_storage_blob.master_ignition_blob.*.url,count.index)}${data.azurerm_storage_account_sas.master_sas.sas}"
  }
}
