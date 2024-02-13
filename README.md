# hashitalks-deploy-boundary
Hashitalks Boundary Deploy


# Steps

1. Build out the AWS environment

```
terraform apply 
```

2. SSH into the work and authenticate the worker

```
ssh -i sshfwkey.pem ubuntu@52.6.212.233
```

3. Get the token key
sudo less boundary/worker/auth_request_token

pdZ5SAAebKa9DmnokkNu5EuBNuyJawUxhgcSEu59Rjwg5d88t1wXvqDEKoxKhet3cBpE3cdnNiQjbMmGk9nSDSwxsmFPkuFQUztHXwr9ntekTPyED5Cxyhnb5dt3RszYGRUWFAEpc1uRFa1Ss8EpBLjQbTfXuADDYgWyWoQkYChNgVzfHMMQadkSXdj96MJHVzDU1zsthT3HLt99qDruDYSR87YW8ND1PNGvKXNQ7fZppckL1dvGJiSuG1hZuHYrypPgA3yNbKY6dyCdPd8ePeLN2NgCSbdsW2QJeg5

4. Update the terraform code /repo with the new token

add the worker with the new token

```
terraform apply 
```

5. Deploy the Target

uncoment target.tf

6. Setup vault 

export VAULT_ADDR="https://vault-cluster-public-vault-cc4cb586.d7f4f2a0.z1.hashicorp.cloud:8200"

export VAULT_TOKEN="hvs.CAESIDR7SP_1ziOiUtpO9ORi_dyAu-1S60l1222ndJ9ZZ41RGicKImh2cy5ocmJReExMY3JnYmcyb0FpMnhqNFJXejEuZjR6dFcQ6Uo"

export VAULT_NAMESPACE=admin


vault kv put secret/my-secret username=ubuntu private_key=@linuxssh.pem


export CRED_STORE_TOKEN=$(vault token create \
  -no-default-policy=true \
  -policy="boundary-controller" \
  -policy="kv-read" \
  -orphan=true \
  -period=20m \
  -renewable=true \
  -field=token)


7. Udpate creds for boundary 

variable

