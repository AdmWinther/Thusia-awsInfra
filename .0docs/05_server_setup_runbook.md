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

## Step 0 — 🖐 Local tooling, source repositories, and AWS credentials
**Why:** Everything after this runs from your own machine: Terraform provisions the
infrastructure and SSHes into the instance, and you use the AWS CLI to check the
account. Neither is installed by anything in this repo.

**Procedure**
1. Install **Terraform** (1.5 or newer) and the **AWS CLI v2**, using whatever
   package manager your OS provides. Confirm both:
   ```
   terraform version
   aws --version
   ```
2. In the AWS console, create an **IAM user for Terraform** — do *not* use the
   account root user. Give it no console access if it is only for Terraform.
3. Attach two customer-managed policies to that user. The first allows EC2 work,
   fenced to the single region you chose above:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "Ec2ManagementInHomeRegionOnly",
         "Effect": "Allow",
         "Action": "ec2:*",
         "Resource": "*",
         "Condition": { "StringEquals": { "aws:RequestedRegion": "<YOUR_REGION>" } }
       }
     ]
   }
   ```
   The second scopes the IAM half to exactly the three objects this repo creates.
   Replace `<ACCOUNT_ID>` with your AWS account number:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Sid": "ManageTheEc2SesRole",
         "Effect": "Allow",
         "Action": [
           "iam:CreateRole", "iam:GetRole", "iam:DeleteRole", "iam:UpdateRole",
           "iam:TagRole", "iam:UntagRole", "iam:ListRoleTags",
           "iam:ListRolePolicies", "iam:ListAttachedRolePolicies",
           "iam:AttachRolePolicy", "iam:DetachRolePolicy",
           "iam:ListInstanceProfilesForRole"
         ],
         "Resource": "arn:aws:iam::<ACCOUNT_ID>:role/role_ec2_full_access_ses"
       },
       {
         "Sid": "ManageTheSesPolicy",
         "Effect": "Allow",
         "Action": [
           "iam:CreatePolicy", "iam:GetPolicy", "iam:DeletePolicy",
           "iam:CreatePolicyVersion", "iam:DeletePolicyVersion",
           "iam:GetPolicyVersion", "iam:ListPolicyVersions",
           "iam:TagPolicy", "iam:UntagPolicy"
         ],
         "Resource": "arn:aws:iam::<ACCOUNT_ID>:policy/policy_ses_full_access"
       },
       {
         "Sid": "ManageTheInstanceProfile",
         "Effect": "Allow",
         "Action": [
           "iam:CreateInstanceProfile", "iam:GetInstanceProfile",
           "iam:DeleteInstanceProfile", "iam:AddRoleToInstanceProfile",
           "iam:RemoveRoleFromInstanceProfile", "iam:TagInstanceProfile",
           "iam:UntagInstanceProfile"
         ],
         "Resource": "arn:aws:iam::<ACCOUNT_ID>:instance-profile/ec2_instance_profile"
       },
       {
         "Sid": "PassTheRoleToEc2Only",
         "Effect": "Allow",
         "Action": "iam:PassRole",
         "Resource": "arn:aws:iam::<ACCOUNT_ID>:role/role_ec2_full_access_ses",
         "Condition": { "StringEquals": { "iam:PassedToService": "ec2.amazonaws.com" } }
       }
     ]
   }
   ```
4. Create an **access key** for that user (type: *Command Line Interface*), then hand
   it to the CLI. The secret is shown only once:
   ```
   aws configure
   ```
   Answer with the access key id, the secret, your region, and `json`.
5. Verify you are the IAM user and not root:
   ```
   aws sts get-caller-identity
   ```
   The `Arn` must end in `:user/<your-user-name>`.
6. **Clone the Joomla component repositories next to this one.** The custom components
   live in their own repositories, and Terraform writes a configuration file *into* two
   of them, so the checkouts must exist before your first `apply`:
   ```
   cd ..                            # the directory that holds this repo
   git clone <url>/JoomlaComponent_SignupForm_JV4
   git clone <url>/JoomlaComponent_NewEmailForm_JV4
   git clone <url>/JoomlaComponent_MaskEmailsList
   git clone <url>/Joomla-Component-Template     # only if you will build new components
   ```
   Then set `joomla_components_path` in `terraform.tfvars` to the directory holding them,
   relative to *this* repo and ending in a slash — `"../"` when they are siblings. They
   stay independent repositories; nothing nests them inside this one.

**Gotchas**
- **A wrong `joomla_components_path` fails silently.** Terraform's `local_file` creates
  any missing parent directory, so a typo or a missing checkout yields a brand-new tree
  containing nothing but the generated config, an `apply` that reports success, and
  components that never receive their settings. After your first apply, confirm each
  file landed *inside* an existing checkout.
- **`aws login` is not enough for Terraform.** The CLI's login session is cached in
  `~/.aws/login/` and read only by the CLI. Terraform reads `~/.aws/credentials`,
  the `AWS_*` environment variables, the SSO cache, or instance metadata — so the
  CLI can be happily authenticated while Terraform reports *"No valid credential
  sources found"*. Use `aws configure` with an access key.
- If you used `aws login` earlier, run `aws logout` and make sure no
  `login_session = …` line is left in `~/.aws/config`. A leftover line can make the
  CLI fail to parse the file at all.
- **`iam:PassRole` is the permission that bites.** Without it, launching the instance
  is rejected the moment it attaches the instance profile, and the error message does
  not clearly say so.
- The region you configure must match the provider region hardcoded in `main.tf`, or
  Terraform and your CLI checks will look at different places.
- Scoping the EC2 policy to an action list instead of `ec2:*` is tempting but
  brittle: a missing action fails the apply **midway**, after the instance exists and
  provisioners have started. Region-fencing is the cheaper guardrail.
- Do not reuse the SES SMTP credentials from Step 6 here. That is a separate identity
  that only needs `ses:SendRawEmail`.

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
- The **public IPv4 address** → `terraform.tfvars : elastic_ip`, **and** the target for
  all your DNS A-records (a later step). `SSL_Fetch.sh` uses this variable to SCP the
  certificates off the server.

**Gotchas**
- The allocation id and the address are **two separate variables describing one Elastic
  IP**, and nothing keeps them in step. If you ever release the address and allocate a
  new one, update both.
- Do not confuse `elastic_ip` with `my_ip_address`: the first is *your server's* address,
  the second is *your own* address, used to restrict SSH.

## Step 3 — 🖐 Look up your VPC id and pick a public subnet
Terraform places the security groups in an **existing** VPC and launches the instance
into an **existing** subnet — it creates neither. Both must be in the same region as
your server.

**Procedure (AWS console):**
1. VPC → *Your VPCs* → copy the **VPC ID** (`vpc-…`) of the VPC you want to use.
2. VPC → *Subnets*, filtered to that VPC → pick a subnet and copy its **Subnet ID**
   (`subnet-…`). It must satisfy two conditions:
   - **Same availability zone** as the EBS data volume you create in Step 4 — an EBS
     volume can only attach to an instance in its own AZ.
   - **Public**, i.e. its route table has a `0.0.0.0/0` route to an **internet
     gateway**. Check under the subnet's *Route table* tab.

**Capture:**
- The VPC ID → `terraform.tfvars : my_vpc_id`
- The Subnet ID → `terraform.tfvars : my_subnet_id`

**Gotchas**
- **"Auto-assign public IPv4" is not what makes a subnet public.** That flag only
  controls whether instances get a public IP automatically; reachability comes from
  the route table. A subnet can have the flag off and still be public — which is the
  normal case here, since `main.tf` sets `associate_public_ip_address = true` itself.
  Conversely, a subnet with the flag on but no internet-gateway route is still private.
- **The instance needs a public IP at launch even though you allocated an Elastic IP.**
  Terraform's file provisioners connect over SSH to the instance's own public address,
  and the Elastic IP is only associated *after* the instance finishes creating. Without
  a launch-time public IP the provisioners have nothing to connect to.
- **If your account has no default VPC**, these values are mandatory. Omitting the
  subnet, or attaching security groups by *name* rather than id, fails with
  `VPCIdNotSpecified: No default VPC for this user. GroupName is only supported for
  EC2-Classic and default VPC` — a confusing message that looks like a permissions
  problem but is not.
- A subnet in the wrong AZ only fails later, when the volume attachment runs — long
  after the instance is created.

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

**Prerequisite:** none for creating the credentials — but SES will not *send*
anything until your sending domain is verified with DKIM in the same region
(Step 8), and the world cannot reach your server until DNS is in place (Step 7).

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

## Step 7 — 🖐 Create the DNS records
**Why:** DNS is what makes the platform reachable at all — the web subdomains Nginx
routes on, the names Let's Encrypt validates, and the MX record that delivers
inbound mask mail to James. Terraform does not touch DNS; you create every record
at whatever provider hosts your domain.

**Prerequisites:** the Elastic IP from Step 2, and your domain set in
`terraform.tfvars : domain_name`.

Using `example.com` as your domain and `<EIP>` as the Elastic IP's public IPv4.
"Apex" below means the **root domain itself**, with no subdomain in front — most
DNS panels want this entered as `@` rather than as a name:

| Type | Name | Value | Why it exists |
|---|---|---|---|
| A | `example.com` (apex, i.e. `@`) | `<EIP>` | Joomla site; cert name |
| A | `www` | `<EIP>` | Joomla; Nginx `server_name www.<domain>` |
| A | `crm` | `<EIP>` | SuiteCRM |
| A | `api` | `<EIP>` | REST API |
| A | `mail` | `<EIP>` | the host your MX points at (James) |
| MX | `example.com` (apex, i.e. `@`) | `10 mail.example.com.` | delivers inbound mask mail to James on port 25 |
| TXT | `example.com` (apex, i.e. `@`) | `v=spf1 mx -all` | SPF — authorizes the server's own direct sends; SES-relayed mail is authenticated by DKIM, not by this record |
| TXT | `_dmarc` | `v=DMARC1; p=none; rua=mailto:dmarc-reports@example.com` | DMARC policy + where reports go |

There is no such host as `apex.example.com` — do not create one. DKIM records are
also **not** in this table; SES generates those for your domain in Step 8.

**Gotchas**
- The four A-records **apex, `www`, `api`, `crm`** are exactly the names
  `SSL_Agent.sh` requests a certificate for in a single certbot run. If even one
  fails to resolve to the server, the entire certificate request fails and none of
  the sites get TLS. `mail` is intentionally excluded — James presents its own
  keystore, not the Let's Encrypt cert.
- An MX record must point to a **hostname that has an A record**, never to an IP
  address. That is the only reason the `mail` A-record exists.
- Inbound SMTP (port 25) is open on the mail security group, so mail reaches James
  as soon as the MX resolves — but AWS blocks *outbound* port 25 on EC2, which is
  why outbound goes through SES (Step 6).
- The DMARC host must be spelled exactly `_dmarc` and the policy must begin exactly
  `v=DMARC1`. Any other spelling is not an error anyone reports to you — receivers
  simply behave as if the domain had no DMARC policy at all.
- Start at `p=none` and read the reports for a while. Only tighten to `quarantine`
  or `reject` once they show your legitimate mail authenticating.
- Do not set `aspf=s` (strict SPF alignment) unless you have completed Step 10 —
  and not even then, since a MAIL FROM subdomain aligns only under `aspf=r`.
  Background: `06_mail_authentication.md` §5.
- `dmarc-reports@` is spelled with a **hyphen**; it is one of the mailboxes
  `james_initialize.sh` creates, so DMARC reports land in a real inbox. (An `fbl@`
  mailbox is created too, for ISP feedback loops.)
- Name syntax differs per provider — some want a bare label (`www`), others the
  fully-qualified name with a trailing dot (`www.example.com.`). Follow your
  provider's convention.
- Before moving on, confirm each name resolves to the Elastic IP:
  `dig +short www.example.com` and `dig +short -t MX example.com`. Records are
  cached for their TTL, so allow propagation time.

## Step 8 — 🖐 Verify your sending domain in SES (DKIM)
**Why:** SES refuses to send mail from an unverified domain. DKIM signing, together
with the SPF and DMARC records from Step 7, is what makes your forwarded mail pass
the receiving side's authentication checks instead of landing in spam.

**Procedure (AWS console):** SES → Configuration → *Identities* → *Create identity*
→ **Domain** → enter your domain (the same value as `domain_name` in
`terraform.tfvars`) → leave **Easy DKIM** selected (RSA_2048).
- If your domain is hosted in Route 53, tick *Publish DNS records to Route 53* and
  SES writes the records itself.
- Otherwise SES shows **three CNAME records** of the form
  `<token>._domainkey.example.com → <token>.dkim.amazonses.com`. Create all three
  at your DNS provider — DKIM is not verified until every one resolves.

Wait for the identity's status to become **Verified** and DKIM configuration to
show **Successful**. This is usually minutes but AWS allows up to 72 hours.

**Gotchas**
- The identity must be verified in the **same region** as the SMTP endpoint in
  `aws_ses_mail_relay_address`. A domain verified in another region does not count.
- Do not delete the DKIM CNAMEs later — SES re-checks them periodically and will
  revoke the verification.
- After this step your mail authenticates on DKIM alone. Step 10 adds SPF as a
  second leg; background in `06_mail_authentication.md` §4 and §6.

## Step 9 — 🖐 Verify the outbound relay end to end
**Why:** Everything from here on assumes mail can actually leave. Proving the relay
on its own — before James, before the application — means that when something later
fails you know it is your mail server, and not your credentials, your DNS, or AWS.

**Prerequisites:** Steps 6 (SMTP credentials), 7 (DNS), 8 (DKIM).

1. Confirm the endpoint offers STARTTLS on the submission port. The endpoint is the
   one recorded in Step 6 — `terraform.tfvars : aws_ses_mail_relay_address`, i.e.
   `email-smtp.<region>.amazonaws.com`; the console also shows it under
   SES → Account dashboard → *SMTP settings* → **SMTP endpoint**:
   ```
   openssl s_client -starttls smtp -crlf -brief \
     -connect email-smtp.<region>.amazonaws.com:587 </dev/null
   ```
   Expect a completed handshake, `Verification: OK`, and a final `250`.
2. If your SES account is still in the **sandbox**, verify the recipient as well:
   SES → Identities → *Create identity* → **Email address**, then click the
   confirmation link. A sandboxed account can only send to verified addresses.
3. Send one authenticated test message through the relay, with `From:` an address at
   your verified domain. Any SMTP client will do (`swaks`, a short `smtplib`
   script, …) as long as it issues STARTTLS on 587 and authenticates with the
   Step-6 credentials. A `250 Ok <message-id>` means SES accepted the message.
4. Open the message at the receiving end and read `Authentication-Results`. You want
   `dkim=pass header.i=@<your-domain>` — Easy DKIM is signing and the signing domain
   matches the `From:` header — together with `dmarc=pass`.

**Gotchas**
- A pass here proves the **endpoint**, not your mail server. James needs
  `<startTLS>true</startTLS>` on its `RemoteDelivery` gateway or it will offer AUTH
  on an unencrypted connection and be rejected with `530 Must issue a STARTTLS
  command first`. Terraform generates that setting for you; if you ever write the
  config by hand, do not omit it.
- A `spf=pass` at this stage is a pass for **Amazon's** domain, not yours, and
  contributes nothing — until Step 10, DMARC is carried by DKIM alone. Two DKIM
  signatures is normal. How to read the verdicts, and which domain each one applies
  to: `06_mail_authentication.md` §6 and §8.
- Note *where* the message landed. Under a `quarantine` policy a DMARC failure goes
  to spam, so the spam folder is itself a diagnostic.

## Step 10 — 🖐 Give SPF a second leg: custom MAIL FROM
**Why:** After Step 9 your DMARC pass rests entirely on DKIM, because SES's envelope
domain is Amazon's and can never align with your `From:` header. A custom MAIL FROM
subdomain moves the envelope into your own domain so SPF aligns too — and if DKIM
ever breaks, your mail still authenticates. The mechanics are in
`06_mail_authentication.md` §6.

**Procedure**
1. SES → Identities → your domain → **Custom MAIL FROM domain** → *Edit*. Enter a
   subdomain that carries no mail of its own; `bounce.example.com` is a good choice.
   **Do not reuse the `mail.` name from Step 7** — that one carries your inbound MX.
2. For **behavior on MX failure** choose **"Use a default MAIL FROM domain"**, not
   "Reject the message". If the DNS is not right, SES then falls back to its own
   domain — the working state you had after Step 9. "Reject" stops your mail dead.
3. Publish the two records SES displays:

   | Type | Name | Value |
   |---|---|---|
   | MX | `bounce` | `10 feedback-smtp.<region>.amazonses.com.` |
   | TXT | `bounce` | `v=spf1 include:amazonses.com ~all` |

4. Relax SPF alignment in your DMARC record: `aspf=s` → `aspf=r`.
5. Wait for the MAIL FROM status to read **Successful**, then repeat the Step 9 test
   send.

**Gotchas**
- Step 4 is **not optional**. A subdomain aligns only under relaxed SPF alignment,
  so without `aspf=r` the whole exercise changes nothing
  (`06_mail_authentication.md` §5).
- The `bounce` TXT record is the one place `include:amazonses.com` genuinely
  belongs: on the envelope domain SES actually uses. Note it is `~all` there, per
  AWS, not `-all`.
- Keep `adkim=s`. DKIM signs your domain exactly, so the strict DKIM leg still
  holds and there is no reason to weaken it.
- Check the DMARC change against an **authoritative** nameserver, not your local
  resolver: `dig +short TXT _dmarc.example.com @<your-ns>`. A cached copy will serve
  the old value for the rest of its TTL and make a correct change look like a
  failed one.
- In the re-test, `smtp.mailfrom=` should now show your `bounce.` subdomain instead
  of `amazonses.com`.

## Step 11 — 🖐 Download the MariaDB JDBC driver (`jdbc.jar`)
**Why:** The Apache James image ships without a database driver. `compose.yml`
bind-mounts a repo-root `jdbc.jar` to `/root/libs/jdbc.jar` inside the container,
and a file provisioner in `main.tf` copies it to the server during `apply`.
Without the file the apply fails at that provisioner; with the wrong file James
starts but cannot reach the database.

**Procedure**
1. Open the MariaDB connectors download page:
   <https://mariadb.com/downloads/connectors/>
2. Select the **Connectors** tab, then choose **"Java 8+ connector"** from the
   product dropdown. Download the plain `.jar` it offers (see the first gotcha).
3. Rename the downloaded file to exactly **`jdbc.jar`**.
4. Move it into the **infra repo root** — the same directory as `main.tf` — because
   the provisioner reads it from `./jdbc.jar`.
5. Confirm you got the right artifact:
   ```
   unzip -p jdbc.jar META-INF/services/java.sql.Driver      # → org.mariadb.jdbc.Driver
   unzip -p jdbc.jar META-INF/MANIFEST.MF | grep Bundle-Version
   ```
6. Check that `db_driver_className` and `db_software` in your `terraform.tfvars`
   agree with what you downloaded — they generate `database.driverClassName` and the
   `jdbc:<db_software>://` URL in `james-database.properties`. For this connector
   they are `org.mariadb.jdbc.Driver` and `mariadb`.

**Gotchas**
- The download page also offers OS packages (`.deb` / `.rpm` / `.msi`). You want the
  bare **JAR**, not an installer.
- The filename is hardcoded in both the compose mount and the file provisioner, so a
  versioned name like `mariadb-java-client-x.y.z.jar` is simply not found. Rename it.
- MySQL's Connector/J is a *different* artifact with a different driver class
  (`com.mysql.cj.jdbc.Driver`). If you switch `db_software`, the jar and
  `db_driver_className` must change together.
- `*.jar` is git-ignored, so this file never travels with the repo — everyone
  building a server downloads their own copy.
- Connector/J 3.x requires Java 8 or newer, which the James JPA image satisfies.
  Even so, check the first James boot log: a driver mismatch surfaces there, not at
  `terraform apply` time.

## Step 12 — 🖐 Fill the passwords and your own IP in `terraform.tfvars`
**Why:** Step 1 copied the example with `TODO-*` placeholders; nothing generates
these for you. None of the variables has a default, so an unfilled one either stops
`terraform plan` to prompt you or — with `-input=false` — fails outright. This step
clears every placeholder except the post-deploy ones.

**Procedure**
1. **`TODO-PWMGR-*` — passwords you invent and store in a password manager.** Sixteen
   of them, in five groups:
   - **Databases** (`db_root_password`, `james_db_password`, `crm-db-password`,
     `joomla_db_password`) — used to create the accounts in `database_init.sql` and
     handed to the services as environment variables.
   - **Mail users** (`admin_password`, `crm_password`, `fbl_password`,
     `dmarc_reports_password`, `joomla_password`, `api_joomla_password`) — one per
     mailbox `james_initialize.sh` creates. You will type these into a mail client
     later, so keep them retrievable.
   - **Application accounts** (`crm_user_password`, `rest_api_db_password`,
     `joomla_admin_username`, `joomla_admin_password`). The last two are the Joomla
     administrator's login, handed to the container as environment variables and used by
     the installer on first boot — so they are set *before* the stack ever runs, not
     clicked in afterwards. The username sits in this group because it is one half of a
     credential; keep both in the password manager. Joomla enforces a 12-character
     minimum on the password.
   - **The James keystore** (`james_keystore_password`) — protects the PKCS12 store that
     serves TLS on SMTP and IMAP. `SSL_Agent.sh` builds the store with it and the
     smtp/imap configs read it back, so all three come from this one variable and cannot
     drift. Apache James's sample configuration ships a well-known default password;
     **do not reuse it** — anyone who obtains the keystore could read your private key.
   - **The mask-request signing key** (`New_Mail_Request_Secret_key`) — a shared secret,
     not a login. Both the Joomla components and the REST API hold it. When a component
     sends a mask request it computes an HMAC-SHA256 over the exact JSON body using this
     key and puts the result in an `X-Signature` header; the API recomputes it with its
     own copy and rejects the request unless the two match. That proves the request came
     from a holder of the key and that the body was not altered on the way — and the key
     itself is never transmitted. Because both ends must hold the *identical* string,
     Terraform writes it into the REST container's environment **and** into both
     components' configuration files (Step 0, item 6), so it is never copied by hand.
     Use a long random alphanumeric string. Rotating it is a two-sided change: re-apply,
     then rebuild and reinstall the components.
2. **`TODO-YOURS-*` — your own environment values.** By this point `domain_name`,
   `key_pair_name` and `ssh_private_key_file` are already set (Steps 5 and 7). Two
   remain: `crm_user_username` (the CRM admin login you want) and `my_ip_address`,
   **your own** public IP for SSH allow-listing — not the server's. Find it with:
   ```
   curl -s https://checkip.amazonaws.com
   ```
   Write it as a single-host CIDR, e.g. `203.0.113.7/32`.
3. **Leave `TODO-POSTDEPLOY-*` alone.** The SuiteCRM OAuth2 client id/secret and the
   Joomla API token are issued by those applications' own admin UIs and cannot exist
   before the stack runs. They are filled in a later step.
4. **Note the three switches that are not placeholders** but decide what an `apply`
   actually does: `bootstrap_run` (Step 13), `certificate_subdomains` (Step 14) and
   `container_volume_initialize` (Step 16). Leave them at their example values for now;
   each is set deliberately in the step that needs it.

**Verify**
```
grep -n "TODO-" terraform.tfvars     # should list only the TODO-POSTDEPLOY-* lines
terraform plan -input=false          # must complete without prompting for input
```
A plan that stops to ask for a value means you missed one; a "Value for undeclared
variable" warning means your tfvars has an entry the configuration no longer
declares.

**Gotchas**
- **Avoid shell metacharacters in passwords.** The mail-user passwords are
  interpolated *unquoted* into generated shell commands
  (`docker exec james bash -c "james-cli AddUser …"`), and the database passwords
  land in generated SQL. A `$`, backtick, quote or backslash will be eaten or will
  break the generated file — and the failure surfaces at container-init time on the
  server, long after `apply` reported success. Long alphanumeric passwords with
  `-` `_` `.` are safe. The mask-request signing key additionally lands inside a
  **single-quoted PHP string**, so a `'` or `\` breaks the component configuration too.
- **The mail-user list and the variable list must agree.** Adding or removing a
  mailbox means touching four places: the `variable` block and the script body in
  `___ShredModules___/file_gen_james_initialize_sh/main.tf`, and the `variable`
  block and module wiring in the root `main.tf` — plus `terraform.tfvars` and
  `terraform.tfvars.example`. Miss the tfvars entry and Terraform prompts for it;
  miss the removal and you get an undeclared-variable warning.
- **`my_ip_address` must be a CIDR, not a bare IP.** It goes straight into the SSH
  rule's `cidr_blocks`, so `203.0.113.7` fails the plan with "is not a valid CIDR
  block". Append `/32`.
- **A home IP is usually dynamic.** When your ISP changes it, SSH ingress stops
  matching; update the value and re-apply.
- `terraform.tfvars` is git-ignored, `terraform.tfvars.example` is **not** — never
  put a real password in the example.

## The chicken-and-egg problem, and how Steps 13–16 solve it
Read this before running anything: it explains why the server is built **twice**.

Nginx needs Let's Encrypt certificates and James needs a keystore — but neither can exist
before the server does. Certbot must prove control of your domain from the machine the DNS
records point at, and it does so over HTTP-01, which needs **port 80**. Nginx publishes
port 80. So the certificates cannot be obtained while the stack that needs them is running.

The way out is a throwaway **bootstrap run**: bring up the instance with the container
stack suppressed, let certbot have port 80, build the keystore from the certificate it
issues, copy both down to your workstation, then destroy it and build the real server with
those files in hand.

```
Step 13  bootstrap apply   → instance up, no containers, port 80 free
Step 14  SSL_Agent.sh      → certbot issues the certificate, keystore is built
Step 15  SSL_Fetch.sh      → four PEMs + keystore land in ./SSL-certificates/
Step 16  production apply  → real certificates provisioned, stack starts
```

Only Step 16 produces the server you keep. Steps 13–15 exist purely to manufacture five
files, and you repeat them only when the certificate needs re-issuing for new names.

## Step 13 — 🖐 The bootstrap run
**Why:** to get a host with a public IP and port 80 free, so certbot can run.

**Procedure**
1. Set `bootstrap_run = "true"` in `terraform.tfvars`. This comments the
   `docker-compose … up -d` line out of `user_data`, so no container starts.
2. Leave `container_volume_initialize = "false"`. The bootstrap host writes nothing worth
   keeping, so there is no reason to format the data volume yet — that belongs to Step 16.
3. **Create the five placeholder files the certificate provisioners require.** Terraform
   copies `./SSL-certificates/{fullchain,privkey,cert,chain}.pem` and
   `./SSL-certificates/keystore` to the server, and a `file` provisioner fails the apply if
   its source is missing. It does not care that the file is empty:
   ```
   mkdir -p SSL-certificates
   touch SSL-certificates/{fullchain,privkey,cert,chain}.pem SSL-certificates/keystore
   ```
4. `terraform apply`.

**Verify:** the instance reaches `running`, and SSH works:
```
ssh -i <your-key>.pem ec2-user@<elastic-ip>
```

**Gotchas**
- **An HCL `provisioner` block cannot be switched off by a variable**, which is why the
  placeholder files are needed rather than a flag. `bootstrap_run` can suppress *shell
  lines* inside `user_data`, but not a provisioner.
- **A private key file must not be group- or world-readable.** OpenSSH refuses it with
  `UNPROTECTED PRIVATE KEY FILE … Permissions 0664 are too open` and falls back to asking
  for a password that does not exist. Fix with `chmod 400 <your-key>.pem`. This is a
  client-side check and has nothing to do with AWS.
- **Expect errors in the boot log, and ignore them.** `user_data` runs under `set -x`, not
  `set -e`, so it continues past failures. On a bootstrap run the `mount` of the
  unformatted volume fails, `chown` on volume subdirectories that do not exist yet fails,
  and the REST-container truststore import fails because no container is running. None of
  these matter here. Read the log with:
  ```
  sudo grep -nE "Thusia server setup|command not found|mount:" /var/log/cloud-init-output.log
  ```
- Terraform's file provisioners connect to the instance's **own** public address, so the
  subnet must give it one at launch (Step 3) — the Elastic IP is associated only after the
  instance finishes creating, which is too late for provisioning.

## Step 14 — 🖐 Obtain the certificate and build the keystore
**Why:** this is the only step that talks to Let's Encrypt. It produces the four PEMs
Nginx mounts and the PKCS12 keystore James serves TLS from.

**Before you run it,** check `certificate_subdomains` in `terraform.tfvars`. It lists the
subdomain labels included alongside the apex, and it must contain **`mail`** — James serves
SMTP and IMAP TLS on that hostname, and a certificate without it makes every mail client
report a name mismatch. Add any other web hostname you intend to serve at the same time.

**Procedure** (on the server, over SSH):
```
sudo chmod +x ~/SSL_Agent.sh
sudo bash ~/SSL_Agent.sh
```
The script installs certbot, requests one certificate covering the apex plus every label in
`certificate_subdomains`, copies the four PEMs into the home directory, builds the keystore
with `openssl pkcs12 -export` using `james_keystore_password`, and restricts the two files
that contain the private key to mode 600.

**Verify:**
```
ls -l ~/{fullchain,privkey,cert,chain}.pem ~/keystore
sudo openssl x509 -in ~/fullchain.pem -noout -dates -ext subjectAltName
```
Every name you asked for must appear in the SAN list.

**Gotchas**
- **Every name is validated, so every name must already resolve to this server.** Certbot
  requests one certificate covering all of them and a single unresolvable label fails the
  **whole** request — you get no certificate at all, not a partial one. Create the DNS
  A-record before adding a label to `certificate_subdomains`.
- **Let's Encrypt allows 5 certificates per week for an identical set of names.** Get the
  name list right before running, rather than issuing repeatedly and discovering the limit.
  Adding a name later costs another issuance, so add planned hostnames up front.
- **Nothing must be listening on port 80.** Certbot `--standalone` binds it itself. This is
  exactly what `bootstrap_run = "true"` guarantees; if you run this on a live server the
  request fails.
- **The keystore is derived from the certificate**, so re-issuing for new names means
  rebuilding it. The script does that automatically on every run — but a keystore you built
  by hand earlier will *not* match a newly issued certificate.
- Terraform copies this script to the server but never executes it. That is deliberate:
  it consumes a rate-limited external resource, so it stays a manual step.

## Step 15 — 🖐 Fetch the certificates and keystore, and verify them
**Why:** the files must live on your workstation, because Terraform provisions them from
`./SSL-certificates/` on every subsequent apply. The bootstrap host is about to be thrown
away.

**Procedure** (on your workstation, from the infra repo root):
```
bash SSL_Fetch.sh
```
It SCPs the four PEMs and the keystore from the server into `./SSL-certificates/`,
overwriting the empty placeholders from Step 13, and restricts `privkey.pem` and `keystore`
to mode 600.

**Verify — do not skip this.** A keystore that cannot be opened with the configured
password is indistinguishable from a good one until James fails to start:
```
openssl pkcs12 -info -in SSL-certificates/keystore \
  -passin pass:<james_keystore_password> -nokeys -noout
```
Success prints the MAC and bag details. `Mac verify error: invalid password?` means the
store does not match your configuration — rebuild it (see below). Confirm the contents
match the certificate too:
```
openssl x509 -in SSL-certificates/fullchain.pem -noout -subject -ext subjectAltName
ls -l SSL-certificates/
```
All five files must be non-empty; a 0-byte file means a placeholder was never overwritten.

**Gotchas**
- **`SSL-certificates/` is git-ignored** (`/SSL-certificates/*` and `*certificate*`), so
  these files never travel with the repo. They are also the only copy of your keystore —
  back them up somewhere safe, because losing them means another certbot issuance.
- **The keystore can be rebuilt locally without the server**, since it derives entirely
  from two PEM files:
  ```
  openssl pkcs12 -export -in SSL-certificates/fullchain.pem \
    -inkey SSL-certificates/privkey.pem -name james \
    -out SSL-certificates/keystore -passout pass:<james_keystore_password>
  chmod 600 SSL-certificates/keystore
  ```
  Read the password out of `terraform.tfvars` rather than retyping it — a typo here
  produces exactly the mismatch this step is checking for.
- Run the script from the repo root. Both the SSH key and the destination are relative
  paths.
- **Do not run it with `sudo`.** The script writes into your own working copy, and under
  `sudo` all five files end up owned by `root`. Because `privkey.pem` and the keystore are
  mode 600, the user you run Terraform as can then no longer read them, and your next
  `apply` fails on exactly those two file provisioners while the three world-readable ones
  succeed — a partial failure that reads like a Terraform bug rather than a permissions
  problem. If it happens, `chown` the directory back to your own user; the permission bits
  are already correct and must not be widened.

## Step 16 — 🖐 The production run
**Why:** this builds the server you keep, with real certificates and the container stack
running.

**Procedure**
1. `bootstrap_run = "false"` — the stack now starts.
2. `container_volume_initialize = "true"` — **only** if the EBS data volume is still
   brand-new and unformatted. This formats it, creates the per-service subdirectories, and
   runs the James and SuiteCRM initializers.
3. `terraform apply`. If a bootstrap instance is still running, the `user_data` change
   replaces it, which is what you want — provisioners only run when an instance is created.
4. **Immediately set `container_volume_initialize` back to `"false"`** and keep it there.

**Verify:** the site answers over HTTPS on each of your hostnames, and on the server:
```
sudo docker ps                    # every container up
sudo docker logs james 2>&1 | tail -40
```

**Gotchas**
- **`container_volume_initialize = "true"` reformats the data volume — it destroys
  everything on it.** It is safe exactly once, on a volume with nothing to lose. Leaving it
  `"true"` means the *next* apply wipes your databases.
- **The mail-user and CRM initializers only run when it is `"true"`**, so on a brand-new
  volume it must be `"true"` for this run or you get a running stack with no mailboxes.
- You can destroy the bootstrap instance first (`terraform destroy`) rather than letting
  Terraform replace it. The Elastic IP and the EBS volume are pre-existing resources that
  Terraform only associates, so neither is destroyed — and the certificates are already
  safely on your workstation.
- The three `TODO-POSTDEPLOY-*` values in `terraform.tfvars` can only be filled after this
  step, from the SuiteCRM and Joomla admin UIs.

## Step 17 — 🖐 Verify the stack and configure SuiteCRM's outbound mail
**Why:** a successful `terraform apply` proves only that AWS accepted your resources. This
step proves the containers actually run, that TLS is *complete* rather than merely present,
and that the CRM can send mail.

**Procedure**
1. On the server, confirm every container is up and the mail server started cleanly:
   ```
   sudo docker ps
   sudo docker logs james 2>&1 | tail -40
   ```
2. From your workstation, check each hostname over HTTPS — and check the **chain**, not
   just the certificate:
   ```
   for h in <domain> www.<domain> api.<domain> crm.<domain> mail.<domain>; do
     echo -n "$h: "
     echo | openssl s_client -connect $h:443 -servername $h 2>&1 | grep 'Verify return code'
   done
   ```
   Every line must read `0 (ok)`.
3. Check the mail ports the same way, which is where a mail client will actually connect:
   ```
   echo | openssl s_client -connect mail.<domain>:993 -servername mail.<domain> 2>&1 | grep 'Verify return code'
   echo | openssl s_client -connect mail.<domain>:465 -servername mail.<domain> 2>&1 | grep 'Verify return code'
   ```
4. Add one mailbox to a desktop mail client: IMAP `mail.<domain>` port 993 with SSL/TLS,
   SMTP `mail.<domain>` port 465 with SSL/TLS, username the **full address**
   (`admin@<domain>`, not `admin`), password from `terraform.tfvars`. Send a message
   between two of your mailboxes.
5. In SuiteCRM, Admin → Email Settings: From Address `crm@<domain>`, SMTP Mail Server
   `mail.<domain>`, SMTP Port 465, "Enable SMTP over SSL or TLS" set to **SSL**, SMTP
   authentication **enabled**, username `crm@<domain>` and its password from
   `terraform.tfvars`. Send the test mail.

**Verify:** every hostname reports `0 (ok)`, the mail client sends and receives, and
SuiteCRM's test mail arrives — check the **spam folder** as well as the inbox, because a
domain with no sending history often lands there first.

**Gotchas**
- **`0 (ok)` is the check that matters, not the list of names in the certificate.** A
  server can present a certificate with every correct name and still be unusable: if it
  sends only the leaf and omits the intermediates, browsers paper over the gap by fetching
  them, while mail clients and anything Java-based simply refuse the connection. Point
  `ssl_certificate` at `fullchain.pem`, never at `cert.pem` — and note that
  `ssl_trusted_certificate` does **not** send the chain to clients; it is for OCSP stapling
  and client-certificate verification.
- **Any hostname without a `server_name` of its own is answered by the default server** —
  the first block listening on that port. Its certificate is what unmatched names such as
  `mail.<domain>` receive, so that one block is effectively your site-wide TLS default,
  whatever its name suggests. Give the apex its own certificate directives rather than
  letting it inherit.
- **A mail client's "add security exception" dialog defaults to port 443**, i.e. your *web*
  server. Typing a bare hostname there tests nginx and never contacts the mail server, so
  the result is misleading. Include the port — `mail.<domain>:993`.
- **The CRM container reaches the mail server over public DNS, not the docker network.**
  The generated `hosts` file is copied only to the server's own `/etc/hosts` and is mounted
  into no container, so this traffic leaves and re-enters through the internet gateway. It
  works, but if that path is ever blocked, give the mail container a network alias for the
  mail hostname rather than pointing the CRM at a container name — the certificate still
  has to match the name the client uses.
- **Point SuiteCRM at a hostname your certificate covers.** SuiteCRM 8 uses PHPMailer,
  which verifies the peer name by default, so a mail host outside the certificate's names
  fails even though the mail server itself is healthy.
- Mail between two local mailboxes never leaves the machine and never touches your outbound
  relay. It proves the mail server works; it proves nothing about relaying to the outside
  world. Test with an external address.

## Step 18 — 🖐 Create the SuiteCRM OAuth2 client for the REST API
**Why:** the REST API is the integration hub — it talks to SuiteCRM to create, list and
delete mask addresses. SuiteCRM authenticates those calls with OAuth2, so the API needs a
client id and secret that can only be issued once SuiteCRM is running. This is one of the
values that cannot be known before deployment, which is why `terraform.tfvars` ships it as
a `TODO-POSTDEPLOY-*` placeholder.

**Procedure**
1. In SuiteCRM: **Admin → OAuth2 Clients and Tokens → New Client Credentials Client**.
   Give it a name that identifies the caller (e.g. "RestAPI") and set its secret.
2. Copy the generated **client id** and the **secret** into `terraform.tfvars`:
   ```
   CRM_API_AuthenticationClientId     = "…"
   CRM_API_AuthenticationClientSecret = "…"
   ```
   These are credentials: they belong in `terraform.tfvars` only, never in a tracked file.
3. **Deploy them.** Filling `terraform.tfvars` alone changes nothing on a running server —
   see the gotchas below. Regenerate the compose file, copy it to the server, and
   **recreate** the API container:
   ```
   terraform apply                       # regenerates compose.yml locally
   scp -i <your-key>.pem compose.yml ec2-user@<domain>:<home-directory>compose.yml
   # on the server, from the directory holding compose.yml:
   sudo docker-compose up -d <rest-api-container-name>
   ```

**Verify:** the API container comes up with the real values rather than the placeholders:
```
sudo docker inspect <rest-api-container-name> \
  --format '{{range .Config.Env}}{{println .}}{{end}}' | grep CRM_API_Authentication
```
Then exercise a mask operation end to end and confirm SuiteCRM accepts the token.

**Gotchas**
- **A container's environment is fixed when the container is created.** `docker restart`
  re-uses it, so it will *not* pick up new values — you must recreate the container
  (`docker-compose up -d <service>`). This is the single most common way to "fill in the
  credentials" and still see the integration fail.
- **`terraform apply` regenerates the compose file locally but does not send it.** File
  provisioners run only when the instance is *created*, so any config change after the
  first apply has to be copied up by hand. The same applies to every other generated file.
- **Check the apply plan before running it on a live server.** If `user_data` has changed
  since the instance was created — for instance because you reset
  `container_volume_initialize` — applying it can stop and start the instance. Confirm
  which of your services declare `restart: always`, because the rest will not come back on
  their own and `user_data` does not re-run on reboot.
- The client secret is stored by SuiteCRM as a hash and cannot be read back from the UI
  afterwards. If you lose it, issue a new client rather than trying to recover it.
- Some SuiteCRM guides suggest copying the client id into a local
  `application.properties` and a Postman environment as well. Those are for developing and
  testing the API by hand; the deployed stack takes its values from `terraform.tfvars`
  through the generated compose file.

## Step 19 — 🖐 Install the user-groups cleanup plugin, then create the API user
**Why:** Joomla's default installation ships several user groups
(Manager/Administrator/Author/Editor/Publisher) this project doesn't use. A custom system
plugin removes them, but it hooks a per-request event rather than running once — leaving
it enabled means it re-runs its cleanup query on every single page load, and will silently
delete any future group that happens to share one of the cleaned titles. Once groups are
cleaned up, the REST API needs its own Joomla user to call the API as — a Super User,
because Web Services Login requires it — and that user's API token is the last credential
`terraform.tfvars` needs.

**Procedure**
1. Immediately after the Joomla install wizard, before creating any custom groups you
   intend to keep, install the cleanup plugin (Extensions → Manage → Install → zip from
   its repo checkout).
2. Enable it once from System → Manage → Plugins so its cleanup runs.
3. **Disable it again right away**, from the same screen.
4. Create a new user of type Super User for the REST API to authenticate as — a dedicated
   address such as `api_joomla@<domain>`, not a personal admin account.
5. Log out of your own admin account and log in as that new user. API tokens are
   per-user, and Joomla generates them under the logged-in user's own profile — there is
   no "create a token for another user" option.
6. Still logged in as that user: Users → Manage → Your User → **API Tokens** tab → create
   a new token.
7. Copy the generated token into `terraform.tfvars`:
   ```
   JOOMLA_API_TOKEN = "…"
   ```
   This is a credential: it belongs in `terraform.tfvars` only, never in a tracked file.
   Deploying it to the running `rest` container follows the same regenerate/copy/recreate
   procedure as Step 18.

**Verify:** Users → Groups shows only the groups you intend to keep; the plugin shows as
disabled in the Plugins list; the new user appears with type Super User; a token-authenticated
request to the Users API (`Authorization: Bearer <token>`) returns `200`, not `401`/`403`.

**Gotchas**
- This plugin uses the legacy (non-namespaced) Joomla plugin format. It has been confirmed
  to load and run on this project's Joomla version, but the format is deprecated.
- The cleanup runs raw `DELETE` queries against the groups table directly. It does not
  clean up group memberships or access-rule references that pointed at the deleted groups
  — those become orphaned rows, harmless but not truly clean.
- A rewrite that runs the cleanup once at install time (via the extension's own install
  script) instead of relying on manual enable/disable is tracked as project follow-up work.
- The token is tied to the user, not to a role — deleting or blocking that Joomla user
  invalidates every token issued to it, including the one already deployed to the REST
  API.

## Next
_(added here as we work through the remaining steps)_
- Step 20: the SuiteCRM email-verification workflow (`README_SuiteCRM.md` step 3) and the
  mask-email module deployment; then installing the custom Joomla components (zip each
  checkout, install through the Joomla admin UI). To be documented once done.