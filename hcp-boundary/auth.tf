
## auth method 


resource "boundary_auth_method_oidc" "provider" {
  name                 = "Azure"
  description          = "OIDC auth method for Azure"
  scope_id             = boundary_scope.org-maniak.id
  issuer               = var.issuer
  client_id            = var.client_id
  client_secret        = var.client_secret
  is_primary_for_scope = true
  signing_algorithms   = ["RS256"]
  api_url_prefix       = "https://bea6dd75-103d-440e-bc65-d8c476d2ddfb.boundary.hashicorp.cloud"
}

resource "boundary_managed_group" "oidc_group" {
  name           = "Azure"
  description    = "OIDC managed group for Azure"
  auth_method_id = boundary_auth_method_oidc.provider.id
  filter         = "\"maniak.io\" in \"/userinfo/upn\""
}

output "managed-group-id" {
  value = boundary_managed_group.oidc_group.id
}

resource "boundary_role" "network_eng_role" {
  name          = "Secure Network Eng"
  description   = "Enhanced Secure Access to Network Eng"
  principal_ids = [boundary_managed_group.oidc_group.id]
  scope_id      = boundary_scope.project_aws.id
}

resource "boundary_role" "platform_eng_role" {
  name          = "Secure Platform Eng"
  description   = "Enhanced Secure Access to Platform Eng"
  principal_ids = [boundary_managed_group.oidc_group.id]
  scope_id      = boundary_scope.project_aws.id
}

resource "boundary_role" "database" {
  name          = "Secure Database Eng"
  description   = "Enhanced Secure Access to Database Eng"
  principal_ids = [boundary_managed_group.oidc_group.id]
  scope_id      = boundary_scope.project_aws.id
}

output "platform_eng_role-id" {
  value = boundary_role.platform_eng_role.id
}
output "network_eng_role-id" {
  value = boundary_role.network_eng_role.id
}
output "database-id" {
  value = boundary_role.database.id
}