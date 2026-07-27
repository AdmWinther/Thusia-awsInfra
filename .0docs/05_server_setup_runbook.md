# Server Setup Runbook (from zero)

> **Purpose:** step-by-step instructions for standing up a Thusia server **from
> scratch on your own AWS account**. Written **incrementally** — each concrete
> action needed to run the server is added as its own step, with the gotchas to
> watch for. It describes what *you* must do; it is **not** a log of any one
> deployment, so it carries no specific IPs, IDs, or dates.
>
> This file is **procedure only**; strategy and status live in the workspace-root
> `progress.md`, and secrets live in your git-ignored `terraform.tfvars`.
> Legend: 🖐 = you do it manually · 🤖 = Terraform does it during `apply`.

## Region & availability zone
Pick one AWS **region** and one **availability zone**, and create **every regional
resource (the EBS volume and the EC2 instance) in that same availability zone** —
otherwise the volume attachment fails. The region and AZ are set in `main.tf` (the
provider `region` and `locals.availability_zone`); change them there if you use
different ones.

## Step 1 — 🖐 Create `terraform.tfvars` from the example
Copy `terraform.tfvars.example` to `terraform.tfvars` (git-ignored via `*.tfvars`,
so your secrets are never committed). Keep every configuration value (images,
ports, container and database names) as-is unless you have a reason to change it,
then replace each `TODO-*` placeholder as you complete the relevant step. The
placeholder category tells you where the value comes from:
- **`TODO-PWMGR-*`** — a password or secret key you choose and store in your
  password manager (database, mail-user, and internal secrets).
- **`TODO-AWS-*`** — a value from the AWS console: VPC id, EBS volume id, SES SMTP
  username/password, Elastic IP allocation id.
- **`TODO-POSTDEPLOY-*`** — generated after the stack is running: SuiteCRM OAuth2
  client id/secret, Joomla API token.
- **`TODO-YOURS-*`** — your own environment value: your domain, your SSH source IP,
  the CRM admin username.

⚠️ `container_volume_initialize` must be `"true"` for the **first** apply against a
brand-new/empty EBS volume (it formats the volume); set it back to `"false"`
afterwards so data is preserved on later applies.

## Step 2 — 🖐 Allocate a static public IP (Elastic IP)
**Why:** your DNS A-records and the server all point at one fixed public IP.
Terraform *associates* a pre-allocated Elastic IP with the instance; it does not
create it.

**Procedure (AWS console):** EC2 → Network & Security → Elastic IPs → *Allocate
Elastic IP address* (your region, Amazon's pool of IPv4 addresses). Do **not**
associate it with anything — `aws_eip_association` attaches it during `apply`.

**Capture:**
- The **Allocation ID** (`eipalloc-…`) → `terraform.tfvars : eip_association_id`.
  ⚠️ Despite its name, this variable takes the *allocation* ID (used as
  `allocation_id` in `main.tf`), not an association ID.
- The **public IPv4 address** → the target for all your DNS A-records (a later
  step). It is **not** a tfvars value; `my_ip_address` is *your own* IP for SSH
  allow-listing, not the server's address.

## Step 3 — 🖐 Look up your VPC id
Terraform places the security groups in an **existing** VPC — it does not create
one. Use your account's default VPC unless you have a reason to use another; it must
be in the same region as your server.

**Procedure (AWS console):** VPC → *Your VPCs* → copy the **VPC ID** (`vpc-…`) of
the VPC you want to use.

**Capture:** the VPC ID → `terraform.tfvars : my_vpc_id`.

## Step 4 — 🖐 Create the persistent EBS data volume
The stack's data (MariaDB, SuiteCRM, Joomla, James) lives on a persistent EBS
volume that Terraform **attaches** to the instance (as `/dev/sdf`, which Linux sees
as `/dev/xvdf`) — it does not create the volume. Make it **at least 10 GiB** and in
the **same availability zone** as the instance (see "Region & availability zone"),
or the attachment fails.

**Procedure (AWS console):** EC2 → Elastic Block Store → *Volumes* → *Create
volume* → type `gp3`, size **≥ 10 GiB**, availability zone = your instance's AZ. Do
**not** attach it manually — Terraform attaches it during `apply`.

**Capture:** the **Volume ID** (`vol-…`) → `terraform.tfvars : containers_volume_id`.

Reminder: `container_volume_initialize` must be `"true"` for the **first** apply
against this brand-new/empty volume (it formats it), then `"false"` afterwards.

## Step 5 — 🖐 Create the SSH key pair
Terraform launches the instance with an EC2 key pair and SSHes in during
provisioning using the matching private key from the repo root. Both the key-pair
name and the private-key filename come from `terraform.tfvars` (variables
`key_pair_name` and `ssh_private_key_file`).

**Procedure (AWS console):** EC2 → Network & Security → Key Pairs → *Create key
pair* → type RSA, format `.pem`. Download the `.pem`, place it in the **repo root**
(git-ignored via `*.pem`), and `chmod 400` it.

**Capture:**
- the key pair's **name** (exactly as shown in EC2 → Key Pairs) →
  `terraform.tfvars : key_pair_name`.
- the **`.pem` filename** you placed in the repo root →
  `terraform.tfvars : ssh_private_key_file`.

## Step 6 — 🖐 Create the SES SMTP credentials (outbound mail relay)
James relays all outbound mail through Amazon SES over SMTP. These credentials go
into `terraform.tfvars` and are rendered into James's `mailetcontainer.xml` (the
`RemoteDelivery` gateway).

**Prerequisite:** verify your sending **domain** in SES (same region as the SMTP
endpoint) and publish its **DKIM** records — otherwise SES rejects mail from that
domain.

**Procedure (AWS console):** SES → Account dashboard → *SMTP settings* → *Create IAM
credentials*. This creates an IAM user with a `ses:SendRawEmail` policy and returns
an **SMTP username** (an access-key-style id, `AKIA…`) and an **SMTP password** (a
base64 string — the *derived* password, not the IAM secret key). Copy both; the
password is shown only once.

**Capture:**
- SMTP username → `terraform.tfvars : aws_ses_smtp_relay_username`
- SMTP password → `terraform.tfvars : aws_ses_smtp_relay_password`

The endpoint host and port are already in tfvars (`aws_ses_mail_relay_address`,
`aws_ses_mail_relay_port` — default `email-smtp.<region>.amazonaws.com` / `587`).

Note: new SES accounts are in the **sandbox** (send only to verified addresses).
Sending to real users' inboxes requires **production access** — request it once the
app is otherwise working end-to-end.

## Next
_(added here as we work through the remaining steps)_