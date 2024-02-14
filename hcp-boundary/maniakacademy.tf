

resource "boundary_scope" "maniakacademy" {
  name                   = "Maniak Academy"
  description            = "Maniak Academy Infrastructure"
  scope_id               = boundary_scope.org-maniak.id
  auto_create_admin_role = true
}




resource "boundary_target" "F5-BIGIP" {
  name         = "F5-BIGIP"
  description  = "F5-BIGIP target"
  type         = "tcp"
  default_port = "22"
  scope_id     = boundary_scope.maniakacademy.id
  address      = "172.16.10.9"


  egress_worker_filter = " \"maniakacademy\" in \"/tags/type\" "
}


variable "worker_generated_maniakacademy_auth_token" {
}


resource "boundary_worker" "worker_maniakacademy" {
  scope_id                    = "global"
  name                        = "worker_maniakacademy"
  description                 = "self managed worker with worker maniak academy"
  worker_generated_auth_token = var.worker_generated_maniakacademy_auth_token
}
