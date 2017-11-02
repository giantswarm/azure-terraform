resource "azurerm_public_ip" "api_ip" {
  name                         = "${var.cluster_name}_api_ip"
  location                     = "${var.location}"
  resource_group_name          = "${var.resource_group_name}"
  public_ip_address_allocation = "static"
  domain_name_label            = "${var.api_dns}"

  tags {
    Environment = "${var.cluster_name}"
  }
}

resource "azurerm_dns_a_record" "api_dns" {
  name                = "${var.api_dns}"
  zone_name           = "${var.base_domain}"
  resource_group_name = "${var.resource_group_name}"
  ttl                 = 300
  records             = ["${azurerm_public_ip.ingress_ip.ip_address}"]
}

resource "azurerm_lb_backend_address_pool" "api-lb" {
  name                = "api-lb-pool"
  resource_group_name = "${var.resource_group_name}"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
}

resource "azurerm_lb_rule" "api_lb" {
  name                    = "api-lb-rule-443-443"
  resource_group_name     = "${var.resource_group_name}"
  loadbalancer_id         = "${azurerm_lb.cluster_lb.id}"
  backend_address_pool_id = "${azurerm_lb_backend_address_pool.api-lb.id}"
  probe_id                = "${azurerm_lb_probe.api_lb.id}"

  protocol                       = "tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "api"
}

resource "azurerm_lb_probe" "api_lb" {
  name                = "api-lb-probe-443-up"
  loadbalancer_id     = "${azurerm_lb.cluster_lb.id}"
  resource_group_name = "${var.resource_group_name}"
  protocol            = "tcp"
  port                = 443
}
