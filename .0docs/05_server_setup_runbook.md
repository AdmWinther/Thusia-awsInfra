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

## Next
_(added here as we work through the remaining steps)_