data "template_file" "cloudinit" {
  template = file("${path.module}/cloudinit.yaml")

  vars = {
    azp_url   = var.azp_url
    azp_token = var.azp_token
    azp_pool  = var.azp_pool
    username = "adminuser"
  }
}

data "template_cloudinit_config" "vm" {
  gzip          = true
  base64_encode = true

  part {
    filename     = "vm.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloudinit.rendered
  }
}

resource "azurerm_network_interface" "placeholder_agent" {
  name                = "placeholder-agent"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "placeholder_agent" {
  name                            = "placeholder-agent"
  resource_group_name             = var.resource_group_name
  location                        = var.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = "LeP@ssw0rd123"
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.vm.rendered
  network_interface_ids           = [azurerm_network_interface.placeholder_agent.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}
