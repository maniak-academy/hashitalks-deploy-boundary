
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

