variable "worker_generated_auth_token" {
  default = "GzusqckarbczHoLGQ4UA25uSRJGs8bXYBMFfBYb3ZCk919h2MUo3unPWJLoA7BNFExxvXnfkXz3fk2pyAHW1qTAgxfmYbtfFTZpXXcTqHWhXJvUganjeScn6UZuVHzW97GmY3rGB6uAESGt5JcQuyCheKkKBANTaT3D2CyTFcN7SoVWiUD5qkV9KHEDxqcecLSjvuW9dpp14hdDKfXF5PTFeJJjNKGypaA3mc3GZkXomWQyXobS7JM3vEkqivRzH6giWU1QivoH83jRoQ3H4ezNH7kuVJrXZecfyLPMAnv"
}


resource "boundary_worker" "worker_aws" {
  scope_id                    = "global"
  name                        = "aws private worker"
  description                 = "self managed worker with worker led auth"
  worker_generated_auth_token = var.worker_generated_auth_token
}
