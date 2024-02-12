disable_mlock = true

listener "tcp" {
  address = "0.0.0.0:9203"
  purpose = "proxy"
}

worker {
  initial_upstreams = ["86de7ac7-2113-b2ee-fee4-e88fcbd2e721.proxy.boundary.hashicorp.cloud:9202"]
  auth_storage_path = "/home/ubuntu/boundary/dockerlab"
  tags {
    type = ["hashitalkslab"]
  }
}