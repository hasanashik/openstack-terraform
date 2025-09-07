# Provision an OpenStack VM, Install Apache with Ansible, and Test via Browser

This repository provisions a VM on OpenStack using Terraform, assigns a Floating IP, and automatically installs Apache HTTP Server with Ansible so you can test from a browser.

It uses:

- Terraform OpenStack provider to create network, subnet, router, security group, instance, floating IP, and association
- A `null_resource` with `local-exec` to run an Ansible playbook against the VM once it’s reachable

---

## Repository layout

```
.
├── ansible.cfg                  # Disables SSH host key checking for first-run simplicity
├── apache.yml                   # Ansible playbook to update and install Apache
├── compute.tf                   # Network + router + FIP + instance + Ansible provisioner
├── provider.tf                  # OpenStack provider configuration
├── security_group.tf            # Security group: SSH(22), HTTP(80), ICMP
├── variables.tf                 # Variables for OpenStack creds and instance settings
├── outputs.tf                   # (Recommended) Prints useful info like the Floating IP
└── terraform_testing.pem        # Private key used by Ansible/SSH (DO NOT COMMIT)
```

> Important: `terraform_testing.pem` should never be committed to version control. Add it to `.gitignore`.

Example `.gitignore` entry:

```
terraform_testing.pem
.terraform/
.terraform.lock.hcl
*.tfstate
*.tfstate.backup
crash.log
```

---

## Prerequisites

- OpenStack project with:
  - One external network (for Floating IPs)
  - A Floating IP pool name
  - An image ID for a Debian/Ubuntu cloud image (the Ansible playbook uses `apt` and the default SSH user is `ubuntu`)
  - A flavor ID
  - An imported keypair that matches your local `terraform_testing.pem` public key
- On your workstation or CI runner:
  - Terraform v1.4+
  - Ansible 2.12+
  - OpenSSH client

Optional (to find IDs with CLI):

```
openstack network list --external            # find the external network id
openstack network list                       # find the FIP pool name (often the external network name)
openstack image list                         # find an Ubuntu/Debian image id
openstack flavor list                        # pick a flavor id
openstack keypair list                       # verify your keypair name
```

---

## Configure

1. **OpenStack credentials and project**: edit `variables.tf` or export `TF_VAR_...` env vars.

   - `openstack_auth_url`
   - `openstack_project`
   - `openstack_user`
   - `openstack_user_password`
   - `openstack_region`

2. **External network and Floating IP pool**: in `compute.tf` update:

   - `external_network_id` under `openstack_networking_router_v2.zaman_router`
   - `pool` under `openstack_networking_floatingip_v2.web_fip`

3. **Image, flavor, keypair**: in `variables.tf` update:

   - `web_server_image_id`
   - `web_server_flavor_id`
   - `user_key_name`

4. **Admin IP restriction** (recommended): set `variable "administrator_ip"` in `variables.tf` to your public IP in CIDR, for example `"203.0.113.10/32"` instead of `"0.0.0.0/0"`.

5. **Private key path**: in `compute.tf`, the `local-exec` provisioner references:
   ```
   --private-key=/home/nokialab/terraform/terraform_testing.pem
   ```
   Change this path to wherever your `terraform_testing.pem` lives. Ensure correct permissions:
   ```
   chmod 600 terraform_testing.pem
   ```

> Note on resource names: if your Terraform version rejects a hyphen in resource labels (e.g., `web-server`), rename it to `web_server` and update references accordingly.

---

## Quick start

```
# 1) Put terraform_testing.pem next to your Terraform files or update the path in compute.tf
chmod 600 terraform_testing.pem

# 2) Initialize providers and modules
terraform init

# 3) Review the plan
terraform plan -out=tfplan

# 4) Apply
terraform apply -auto-approve tfplan

# 5) Get the Floating IP (if you added outputs.tf; see below)
terraform output web_server_floating_ip

# 6) Test HTTP
curl http://<FLOATING_IP>

# 7) Open a browser to http://<FLOATING_IP>

# 8) SSH if needed
ssh -i terraform_testing.pem ubuntu@<FLOATING_IP>
```

---

## Outputs (recommended)

Create `outputs.tf` to print useful information:

```hcl
output "web_server_floating_ip" {
  description = "Floating IP of the web server"
  value       = openstack_networking_floatingip_v2.web_fip.address
}

output "web_server_id" {
  description = "Instance ID"
  value       = openstack_compute_instance_v2.web-server.id
}
```

If you renamed the instance to `web_server`, update the references accordingly.

---

## What the Ansible playbook does

- Updates the package index and installs all available updates (`apt upgrade: dist`)
- Installs Apache (`apache2`)
- Uses `ansible.cfg` to skip host key prompts on first connection

By default, Ubuntu images expose the `ubuntu` user for SSH. If your image differs (e.g., `debian` or `cloud-user`), change the `-u` in the `ansible-playbook` command inside `compute.tf`.

---

## Teardown

```
terraform destroy -auto-approve
```

This will remove the VM, networking, floating IP, and security group created by this configuration.

---

## Troubleshooting

- **Ansible times out**: Increase the `sleep` value in the `local-exec` command (cloud-init may still be configuring the VM). 60–120 seconds is common for first boots.
- **Cannot SSH**: Ensure `administrator_ip` in `variables.tf` allows your public IP, the keypair matches your `terraform_testing.pem`, and security groups are attached.
- **HTTP not responding**: Confirm Apache installed successfully and port 80 is allowed in the security group. Some images enable host firewalls (UFW) by default; open port 80 or disable the firewall.
- **Apt errors**: Ensure the image is Debian/Ubuntu and has outbound internet access (egress). If your cloud restricts egress, add explicit egress rules.
- **TLS verify**: `insecure = true` in `provider.tf` disables certificate verification. Prefer trusted certificates in production.

---

## Security notes

- Restrict SSH to your own IP (`administrator_ip = "x.x.x.x/32"`).
- Never commit private keys. Rotate keys periodically.
- Consider removing `insecure = true` and using valid CA certificates for your OpenStack endpoint.

---
