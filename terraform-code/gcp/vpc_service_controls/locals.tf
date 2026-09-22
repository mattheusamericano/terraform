locals {
  ingress_perimeters = {
    for key, rule in var.ingress_policies : key => "accessPolicies/${rule.access_policy_id}/servicePerimeters/${rule.perimeter_name}"
  }

  egress_perimeters = {
    for key, rule in var.egress_policies : key => "accessPolicies/${rule.access_policy_id}/servicePerimeters/${rule.perimeter_name}"
  }
}
