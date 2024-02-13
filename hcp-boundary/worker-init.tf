variable "worker_generated_auth_token" {
}


resource "boundary_worker" "worker_aws" {
  scope_id                    = "global"
  name                        = "aws private worker"
  description                 = "self managed worker with worker led auth"
  worker_generated_auth_token = var.worker_generated_auth_token
}
