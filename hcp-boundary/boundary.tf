
resource "boundary_scope" "global" {
  global_scope = true
  scope_id     = "global"
}

resource "boundary_scope" "org-maniak" {
  name                     = "Maniak Org"
  description              = "Maniak Lab Infrastructure"
  scope_id                 = boundary_scope.global.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project_aws" {
  name                   = "AWS"
  description            = "AWS EC2 Project"
  scope_id               = boundary_scope.org-maniak.id
  auto_create_admin_role = true
}


resource "boundary_worker" "worker_aws" {
  scope_id                    = "global"
  name                        = "aws private worker"
  description                 = "self managed worker with worker led auth"
  worker_generated_auth_token = var.worker_generated_auth_token
}

resource "boundary_host_catalog_static" "platform_eng" {
  name        = "PlatformEng"
  description = "Platform Catalog"
  scope_id    = boundary_scope.project_aws.id
}



resource "boundary_host_static" "linux" {
  type            = "static"
  name            = "linux"
  host_catalog_id = boundary_host_catalog_static.platform_eng.id
  #scope_id        = boundary_scope.project_aws.id
  address = aws_instance.linux_ec2.private_ip
}



resource "boundary_target" "linux" {
  name         = "linux"
  description  = "linux target"
  type         = "ssh"
  default_port = "22"
  scope_id     = boundary_scope.project_aws.id
  # address = aws_instance.linux_ec2.private_ip
  host_source_ids = [
    boundary_host_set_static.platform_eng.id
  ]
  egress_worker_filter                       = " \"workeraws\" in \"/tags/type\" "
  injected_application_credential_source_ids = [boundary_credential_library_vault.vault_cred_lib.id]
  depends_on                                 = [boundary_credential_library_vault.vault_cred_lib]
}

resource "boundary_target" "F5-BIGIP" {
  name         = "F5-BIGIP"
  description  = "F5-BIGIP target"
  type         = "tcp"
  default_port = "22"
  scope_id     = boundary_scope.project_aws.id

  egress_worker_filter = " \"workeraws\" in \"/tags/type\" "
}

resource "boundary_host_set_static" "platform_eng" {
  type            = "static"
  name            = "PlatformEng"
  host_catalog_id = boundary_host_catalog_static.platform_eng.id

  host_ids = [
    boundary_host_static.linux.id
  ]
}



resource "boundary_credential_store_vault" "vault_cred_store" {
  name          = "boudary-vault-credential-store"
  description   = "Vault Credential Store"
  address       = "https://vault-cluster-public-vault-cc4cb586.d7f4f2a0.z1.hashicorp.cloud:8200"
  token         = var.boundary_token
  namespace     = "admin"
  scope_id      = boundary_scope.project_aws.id
  worker_filter = " \"workeraws\" in \"/tags/type\" "
}


resource "boundary_credential_library_vault" "vault_cred_lib" {
  name                = "boundary-vault-credential-library"
  description         = "Vault SSH private key credential"
  credential_store_id = boundary_credential_store_vault.vault_cred_store.id
  path                = "secret/data/my-secret"
  http_method         = "GET"
  credential_type     = "ssh_private_key"
}


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
  api_url_prefix       = "https://bbfa138d-ba47-4a0b-9979-7ffb2fb1022e.boundary.hashicorp.cloud"
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