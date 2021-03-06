resource "azurerm_lb" "ingress_lb" {
  name                = "${var.cluster_name}-ingress-lb"
  location            = var.location
  resource_group_name = var.resource_group_name

  frontend_ip_configuration {
    name                          = "ingress"
    public_ip_address_id          = azurerm_public_ip.ingress_ip.id
    private_ip_address_allocation = "dynamic"
  }

  tags = {
    GiantSwarmInstallation = var.cluster_name
  }
}

resource "azurerm_public_ip" "ingress_ip" {
  name                = "${var.cluster_name}_ingress_ip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"

  tags = {
    GiantSwarmInstallation = var.cluster_name
  }
}

# We need explicitly add this entry for apps like happa.g8s.<base> to be working.
# In Azure this is required (not needed in AWS) and looks like it's aligned with RFC.
# https://tools.ietf.org/html/rfc1034#section-4.3.3
resource "azurerm_dns_a_record" "g8s_wildcard_dns" {
  name                = "*.${var.api_dns}"
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.ingress_ip.ip_address]
}

resource "azurerm_dns_a_record" "ingress_wildcard_dns" {
  name                = "*"
  zone_name           = var.base_domain
  resource_group_name = var.resource_group_name
  ttl                 = 300
  records             = [azurerm_public_ip.ingress_ip.ip_address]
}

resource "azurerm_lb_backend_address_pool" "ingress-lb" {
  name                = "ingress-lb-pool"
  resource_group_name = var.resource_group_name
  loadbalancer_id     = azurerm_lb.ingress_lb.id
}

resource "azurerm_lb_rule" "ingress_http_lb" {
  name                    = "ingress-lb-rule-80-30010"
  resource_group_name     = var.resource_group_name
  loadbalancer_id         = azurerm_lb.ingress_lb.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id                = azurerm_lb_probe.ingress_30010_lb.id

  protocol                       = "tcp"
  frontend_port                  = 80
  backend_port                   = 30010
  frontend_ip_configuration_name = "ingress"
}

resource "azurerm_lb_probe" "ingress_30010_lb" {
  name                = "ingress-lb-probe-30010-up"
  loadbalancer_id     = azurerm_lb.ingress_lb.id
  resource_group_name = var.resource_group_name
  protocol            = "tcp"
  port                = 30010
}

resource "azurerm_lb_rule" "ingress_https_lb" {
  name                    = "ingress-lb-rule-443-30011"
  resource_group_name     = var.resource_group_name
  loadbalancer_id         = azurerm_lb.ingress_lb.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id                = azurerm_lb_probe.ingress_30011_lb.id

  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 30011
  frontend_ip_configuration_name = "ingress"
}

resource "azurerm_lb_probe" "ingress_30011_lb" {
  name                = "ingress-lb-probe-30011-up"
  loadbalancer_id     = azurerm_lb.ingress_lb.id
  resource_group_name = var.resource_group_name
  protocol            = "tcp"
  port                = 30011
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Azure requires the probe to be associated with a load balancer the VMSS belongs to.
# This probe has to be referenced by an active forwarding rule.
# Since we don't want to expose SSH through the load balancer, we use random port 65000.
resource "azurerm_lb_rule" "ingress_ssh_lb" {
  name                    = "ingress-lb-fake-rule-for-node-health"
  resource_group_name     = var.resource_group_name
  loadbalancer_id         = azurerm_lb.ingress_lb.id
  backend_address_pool_id = azurerm_lb_backend_address_pool.ingress-lb.id
  probe_id                = azurerm_lb_probe.ssh.id

  protocol                       = "tcp"
  frontend_port                  = 65000
  backend_port                   = 65000
  frontend_ip_configuration_name = "ingress"
}

# Workers in VMSS are rolled with Rolling upgrade feature.
# That feature automatically reimages one node at a time and waits for it to come back healthy before it goes on with other nodes.
# To understand when a node is healthy, a load balancer probe has to be set. 
# We use port 22 for this probe (not ideal, but does the job for now).
resource "azurerm_lb_probe" "ssh" {
  name                = "ssh-probe"
  loadbalancer_id     = azurerm_lb.ingress_lb.id
  resource_group_name = var.resource_group_name
  protocol            = "tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}
