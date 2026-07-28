# 06 — Mail authentication: SPF, DKIM, and DMARC

Background for the mail-related steps of the server setup runbook (Steps 7–10).
The runbook tells you *what to click*; this explains *why*, so the gotchas there
can stay short. Read this once and the DNS records stop looking arbitrary.

Throughout, `example.com` stands for your own domain.

## 1. The problem SMTP leaves open

SMTP was specified in 1982 with no notion of sender authorization. Any machine on
the internet may open a connection and announce that it is sending mail from any
address. Nothing in the protocol contradicts it.

SPF, DKIM, and DMARC are three layers added later to close that hole. They are
often named in one breath, but each solves a different part of the problem, and
they are only useful together — which is what DMARC exists to arrange.

## 2. Two sender addresses

Every message carries two sender addresses, and almost every subtlety below comes
from the gap between them.

| | Where it lives | Who sees it | Used for |
|---|---|---|---|
| **Envelope sender** | the `MAIL FROM` SMTP command; recorded as `Return-Path:` | nobody, in normal use | bounce delivery |
| **Header From** | the `From:` header inside the message | the recipient, in their mail client | identifying the sender |

They need not match, and for relayed mail they usually do not.

The consequence worth memorising: **SPF checks the envelope sender; DMARC cares
about the header From.** A message can pass SPF perfectly for one domain while
displaying an address at a completely different one.

## 3. SPF — is this server allowed to send for this domain?

The domain owner publishes a TXT record listing the hosts authorized to send its
mail. The receiver takes the **envelope sender's** domain, looks up that record,
and checks the connecting IP against it.

```
v=spf1 mx -all
```

Common mechanisms: `mx` (whatever the domain's MX records point at), `ip4:` /
`ip6:` (literal addresses), `include:` (defer to another domain's record — used
when a third party sends on your behalf), and a final catch-all: `-all` means
"anything else is a forgery, reject it", `~all` means "treat as suspicious".

**Its blind spot:** SPF validates a domain the recipient never sees. Passing SPF
for `attacker.example` says nothing about the `From: ceo@example.com` in the
message body. On its own, SPF cannot stop the impersonation it appears to address.

## 4. DKIM — was this message authorized by this domain, and is it intact?

The sending system signs the message — selected headers, plus a hash of the body —
with a private key, and attaches the result as a `DKIM-Signature:` header. The
matching public key is published in DNS. Two fields identify it:

- `d=` — the **signing domain**
- `s=` — the **selector**, so one domain can hold several keys at once

Given `s=abc123; d=example.com`, the receiver fetches the TXT record at
`abc123._domainkey.example.com`, reads the public key, and verifies the signature.

Two properties matter:

- **It survives relaying.** The signature travels inside the message, so it still
  verifies after passing through intermediate servers — unlike SPF, which is
  invalidated the moment a different host does the connecting.
- **It breaks if the message is modified.** Altering a signed header or the body
  invalidates the signature. Mailing lists that append footers routinely do this.

With SES **Easy DKIM**, AWS generates and holds the private key and you publish
three CNAMEs pointing at AWS-hosted public keys. You never handle key material,
and AWS rotates the keys. The trade-off: those CNAMEs must remain in place — SES
re-checks them periodically and revokes the domain's verification if they vanish.

## 5. DMARC — tie the other two to the address the human sees

DMARC is the layer that makes SPF and DKIM meaningful. It is published as a TXT
record at `_dmarc.example.com`:

```
v=DMARC1; p=quarantine; rua=mailto:dmarc-reports@example.com; adkim=s; aspf=r
```

It does three things.

**It demands alignment.** A DMARC pass requires at least one of SPF or DKIM to
both *pass* **and** *match the domain in the visible `From:` header*. A pass for an
unrelated domain counts for nothing. This is precisely what closes SPF's blind
spot — and note that one aligned pass is enough; the other mechanism may fail.

**It declares a policy** — `p=` tells receivers what to do when nothing aligns:

| Policy | Effect |
|---|---|
| `p=none` | do nothing, just send reports |
| `p=quarantine` | treat as suspicious — typically the spam folder |
| `p=reject` | refuse the message at the door |

`sp=` sets a separate policy for subdomains. Start at `p=none`, read the reports
until legitimate mail is authenticating, and only then tighten.

**It requests reports** — `rua=` is the address for aggregate XML reports.

### Alignment: strict vs relaxed

This is the detail that decides whether a setup works.

| Mode | Tag | Requirement | `bounce.example.com` vs `example.com` |
|---|---|---|---|
| **Strict** | `adkim=s` / `aspf=s` | exact domain match | ✗ does not align |
| **Relaxed** (default) | `adkim=r` / `aspf=r` | same organizational domain | ✓ aligns |

Relaxed alignment accepts a subdomain; strict does not. Any design that puts the
envelope sender on a subdomain therefore requires `aspf=r` to be worth anything.

## 6. What this means when relaying through SES

By default, SES uses **its own** envelope sender: `<id>@<region>.amazonses.com`.
Two consequences follow, and both surprise people:

- SPF is evaluated against **`amazonses.com`**, not your domain. It passes — SES's
  own record authorizes SES's own servers — but it aligns with nothing, so it
  contributes nothing to DMARC. Your mail is resting on DKIM alone.
- Adding `include:amazonses.com` to your **apex** SPF record accomplishes exactly
  nothing for SES-relayed mail, because that record is never the one consulted.
  Your apex record only needs to authorize whatever sends directly *as* your
  domain — typically just the server itself, i.e. `v=spf1 mx -all`.

The fix is a **custom MAIL FROM domain**: you nominate a subdomain such as
`bounce.example.com`, SES uses it as the envelope sender, and SPF is then evaluated
against a domain that is yours. Because it is a *subdomain*, this only aligns under
`aspf=r` — the DMARC record must be relaxed at the same time or the change is
inert. Runbook Step 10 walks through it.

Keep `adkim=s` regardless: DKIM signs your domain exactly, so the strict DKIM leg
still holds and there is no reason to weaken it.

Finally, SES signs every message **twice** — once with your domain's key and once
with `amazonses.com`. This is normal and not a misconfiguration.

## 7. What this means for forwarding

Forwarding is where mail authentication is genuinely hard, and no configuration
fully solves it.

When a server receives a message and forwards it onward, the `From:` header still
names the **original** sender. The receiving system therefore evaluates DMARC
against *that* domain, whose policy you do not control:

- **SPF is hopeless.** The connecting host is now the forwarder, which the original
  domain's record never authorized.
- **The original DKIM signature may survive** — but only if the forwarder left the
  signed headers and body untouched.
- **Re-signing does not help.** A forwarder signing with its own domain produces a
  valid signature for the wrong domain; it cannot align with someone else's
  `From:`.

So a forwarded message from a sender publishing `p=reject` can be discarded, and
there is nothing the forwarder can do about that domain's DNS.

The established remedy is to **rewrite the header From** into a domain you control,
preserving the original as a reply target:

```
From:     "Original Sender via Example" <forwarding-address@example.com>
Reply-To: original.sender@third-party.example
```

DMARC is then evaluated against `example.com`, which you can authenticate. This is
why mailing-list mail so often shows "via" — the pattern is decades old.

Two related mechanisms are worth knowing, neither a substitute for the above:

- **SRS** (Sender Rewriting Scheme) rewrites the *envelope* sender so SPF survives
  a forward. It does not affect DMARC, which looks at the header From.
- **ARC** (Authenticated Received Chain) lets a forwarder attach a sealed record of
  the authentication results it observed, so a downstream receiver can choose to
  trust that assessment. It is advisory — receivers decide whether to honour it.

## 8. Reading an `Authentication-Results` header

The receiver records its verdicts in the message. Most mail clients expose the raw
headers ("Show original" in Gmail). A typical result for a well-configured SES
setup with a custom MAIL FROM:

```
Authentication-Results: mx.example-receiver.com;
  dkim=pass header.i=@example.com header.s=abc123;
  dkim=pass header.i=@amazonses.com header.s=xyz789;
  spf=pass smtp.mailfrom=0100…@bounce.example.com;
  dmarc=pass (p=QUARANTINE sp=QUARANTINE dis=NONE) header.from=example.com
```

Read it as follows:

- **Always check *which domain* each verdict applies to.** `spf=pass` next to
  `smtp.mailfrom=…@amazonses.com` is a pass for Amazon, not for you. The same
  verdict next to `…@bounce.example.com` is a pass for you.
- `header.i=` on the DKIM lines is the signing domain — compare it against
  `header.from=` to judge alignment yourself.
- `dmarc=pass` does not say *which* mechanism carried it. Infer it: if the only
  aligned mechanism was DKIM, then DKIM is the single point of failure.
- `dis=` is the disposition actually applied — `dis=NONE` means the policy was not
  invoked.
- Note **where the message landed**, not just what the headers say. Under
  `p=quarantine`, a DMARC failure goes to spam, so the folder is itself a signal.

## Quick reference

| Record | Name | Purpose |
|---|---|---|
| TXT | `example.com` | SPF for direct sends |
| TXT | `_dmarc.example.com` | DMARC policy, alignment mode, report address |
| CNAME ×3 | `<token>._domainkey.example.com` | DKIM public keys (SES Easy DKIM) |
| MX | `bounce.example.com` | SES custom MAIL FROM — bounce delivery |
| TXT | `bounce.example.com` | SPF for the SES envelope domain |