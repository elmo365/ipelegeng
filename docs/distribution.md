# Distribution strategy — Facebook as a channel, not a rival

## The principle

Don't compete with Facebook for attention. **Use it as top-of-funnel and keep
the transaction in the app.**

This comes directly from the Lynk post-mortem in
[comparable-platforms](comparable-platforms.md): its reach was constrained by
Facebook Marketplace and Instagram, which had wider and more trusted reach, in a
market where word-of-mouth referral remained dominant. Being a better product
than a Facebook group did not win, because nobody was looking.

Ipelege's answer: go where the audience already is, and pull them back.

- **Facebook = discovery.** People already scroll it daily.
- **Ipelege = transaction.** Verified providers, booking, ratings, recourse.

## ⚠️ The constraint that shapes everything here

**Meta deprecated the Facebook Groups API on 22 April 2024**, announced in
January 2024 alongside Graph API v19.0 and removed from all versions 90 days
later. The `publish_to_groups` and `groups_access_member_info` permissions went
with it. Meta cited spam prevention and community protection. No third-party
tool — Buffer, Hootsuite, Zapier, anything — can publish to a Facebook group via
API any more. Cloud tools that still advertise "Facebook Groups" do
*notification posting*: they ping your phone and you paste it in yourself.

**Posting to Pages you own still works fully via the Graph API.**

This matters because of where the demand actually is:

| Surface | Auto-posting | Where your market is |
|---|---|---|
| **Facebook Page** (yours) | ✅ Automatable | Nobody yet — you build this audience |
| **Facebook Groups** (rental, community) | ❌ Manual only | **This is where the rental market lives** |
| **Facebook Marketplace** | ❌ No public posting API | Significant informal listing volume |

So the honest position: **the part of Facebook you can automate is the part
with no audience, and the part with the audience cannot be automated.**

That doesn't sink the strategy. It changes it from an engineering feature into a
growth-operations job with a small engineering assist.

## What to actually build

### Phase 1 — Page auto-posting (buildable)

When a listing goes live in the app, publish a post to the Ipelege Facebook
Page via the Graph API.

**Requirements**
- Facebook App with `pages_manage_posts` and `pages_read_engagement`
- App Review — allow lead time; this is not instant
- Long-lived Page access token, with refresh handling
- Retry and failure logging; a failed post must never block the listing itself

**Post the teaser, not the listing.** Photo, category, area, price band, and a
deep link back to the app. See the leakage rules below — this is a hard
constraint, not a style preference.

## No contact details in outbound posts — hard rule

If a post carries a phone number, the transaction happens on Facebook and the
platform earns nothing. Every outbound post must be constructed so that
completing the job requires opening the app.

### Rules

| Rule | Implementation |
|---|---|
| **No phone numbers, emails, or handles in any outbound post** | Posts are rendered from *structured fields* (category, area, price band, photo) — never from free text a provider typed |
| **No exact address** | Area or suburb only. Exact location is app-side |
| **No provider full name** | First name or trading name only |
| **Contact details stripped at source** | Validate listing free-text on creation; reject Botswana phone-number patterns, emails and social handles with a clear message explaining why |
| **Photos checked** | A signboard, vehicle door or shopfront in a photo often carries a number. Run digit/OCR detection on images used in outbound posts, and exclude flagged ones |
| **Comments moderated** | Someone will comment "how much? call me" and a provider will answer with their number. Use the Page moderation blocklist for number patterns and common phrasings, and review comments daily |

### Be honest about the limits

These rules stop *your* post leaking contacts. They do not stop disintermediation
in general, and it is worth naming that plainly:

- **Providers already post their own numbers in those same groups.** You are
  competing with their existing posts, not replacing them.
- **After the first job, the parties have each other's numbers anyway.** Nothing
  in the design prevents the second job happening off-platform.
- **You have no payment lock-in.** Because customer and provider settle directly
  (a deliberate regulatory choice — see [compliance](compliance.md)), the
  platform never sits in the money flow. The usual marketplace retention lever
  is unavailable by construction.

> **This is the same tension the Lynk evidence raises** in
> [comparable-platforms](comparable-platforms.md): a lead-gen posture with no
> payment control leaks repeat business by default. Fencing helps at the margin;
> it is not a strategy.

**What actually retains, given the above:** verification the parties can't get
elsewhere, dispute recourse, accumulated ratings a provider does not want to
abandon, and convenience for the *next* job in a different category. That last
one is the ecosystem principle earning its keep — the mover who leaves for job
two still comes back when they need a plumber.

Build the fence, but do not mistake it for the moat.

### Phase 2 — Groups, done by hand

Groups are where the rental audience is. That work is manual and human:

- Post as the Ipelege page or a staff account into relevant Gaborone and
  Francistown groups
- Respect group rules; many ban commercial posts outright
- **Watch spam limits.** Common guidance is roughly 3–5 groups per day, spaced
  out, with varied wording — identical content across groups triggers spam
  detection
- Vary the copy per group; don't paste the same text

This is a recurring operational cost, and it should be budgeted as a role rather
than assumed away. It is also, realistically, how the first hundred providers
arrive.

### Phase 3 — Measure it

Deep links with a source parameter, so you can answer: does Facebook actually
convert, or is it just visible? If a group post drives ten installs and no
bookings, that changes the plan.

## Data protection — this is not optional

**Publishing a user's listing to Facebook is a disclosure of personal data to a
third party.** Under the Data Protection Act 2024 (see
[compliance](compliance.md)) that requires:

- **Explicit, granular, opt-in consent** — a separate toggle at listing
  creation, defaulted **off**. Not buried in general terms.
- **Withdrawable** — and withdrawal must actually trigger takedown of existing
  Facebook posts. Build the delete path, not just the create path.
- **Recorded and versioned** in `CONSENT_RECORD` (see
  [data-model](data-model.md))
- **Minimised** — teaser posting is also the privacy-correct choice, not just
  the commercially smart one

A landlord who did not consent to appearing on Facebook and finds themselves
there is both a legal problem and a trust problem, in a product whose whole
pitch is trust.

## Risks to hold in view

| Risk | Mitigation |
|---|---|
| **Cannibalisation** — users transact on Facebook instead of the app | Teaser only; contact details app-side only |
| **Page flagged as spam** | Rate-limit, vary content, don't bulk-post |
| **Platform dependency** — Meta changed the rules once and can again | Note both Facebook *and* WhatsApp are Meta. Concentration risk is real: keep direct provider relationships and phone numbers you own |
| **Consent gaps** | Opt-in default-off, takedown path built |
| **Group admin bans** | Read group rules; consider partnering with admins rather than posting past them |

## WhatsApp — the provider-side channel

Confirmed as a channel. It matters differently from Facebook: **Facebook is
where customers discover, WhatsApp is where providers already work.** The
problem statement names WhatsApp status posts as the existing way providers
reach people — so this is not introducing a new habit, it is meeting one.

### Two products, pick deliberately

| | **WhatsApp Business App** | **WhatsApp Business Platform (API)** |
|---|---|---|
| Cost | Free | Per delivered template message |
| Use | Manual, human conversations | Automated notifications at volume |
| Fit | Provider recruitment, seeding, support | Booking alerts, OTP, reminders |
| When | **Now — through beta** | Once volume justifies the setup |

**Start with the free Business App.** During seeding you are having a hundred
individual conversations with truck owners and landlords, not sending
broadcasts. The API is engineering work and cost for a problem you don't have
yet.

### How the pricing works, when you get there

Billing moved to **per delivered template message on 1 July 2025**, replacing
the old 24-hour conversation model. Each template is billed individually based
on the recipient's country code and the message category.

| Category | Cost | Use for |
|---|---|---|
| **Utility** | Low — roughly 80–90% below marketing; volume discounts apply | Booking confirmations, provider job alerts, reminders |
| **Authentication** | Lowest | OTP at signup |
| **Marketing** | Highest, **no volume discount at any volume** | Listing promotion, campaigns |
| **Service** (free-form replies) | Free inside an open 24-hour window | Support conversations |

Two consequences worth designing around:

1. **Transactional messaging is cheap; promotional messaging is not.** Marketing
   templates carry no volume discount — deliberately, to make blasting
   expensive. Do not build a growth plan on WhatsApp broadcast; build it on
   Facebook reach and let WhatsApp carry the transactional load.

2. **WhatsApp may be cheaper than SMS for OTP** (FR-1.2). Authentication
   templates are the lowest-priced category. Worth pricing against local SMS
   gateway rates for Botswana before committing to SMS.

### Two things to verify

- **Botswana's rate.** Rates are per recipient country and Botswana's is not in
  the sources reviewed. Check Meta's current rate card directly.
- **The free service window is changing.** Reporting indicates free-form and
  service messages are free through 30 September 2026, becoming chargeable from
  1 October 2026. If support-by-WhatsApp is part of the plan, that changes the
  cost model — confirm against Meta's documentation before relying on it.

### Same consent rules apply

Messaging a user on WhatsApp is processing their personal data. Opt-in,
granular, versioned in `CONSENT_RECORD`, withdrawable — as with Facebook
posting. Template content also needs pre-approval from Meta, and templates are
commonly rejected on structure, so allow lead time.

### Suggested split

| Channel | Job |
|---|---|
| **Facebook Page + groups** | Customer-side discovery, listing visibility |
| **WhatsApp Business App** | Provider recruitment and support, by hand |
| **WhatsApp API (later)** | Booking notifications, OTP, reminders |
| **In-app push** | Secondary — unreliable on low-end Android, which is NFR-1 |

## Open

- [ ] Facebook App Review lead time — start early if Page posting is wanted at launch
- [ ] Who owns manual group posting as an ongoing role
- [ ] Teaser post format and how much detail is too much
- [ ] Does the takedown-on-withdrawal path work reliably via the API
- [ ] Meta's current WhatsApp rate card for **Botswana** specifically
- [ ] Confirm whether free service-window messaging ends 1 October 2026
- [ ] Price WhatsApp authentication templates against local SMS for OTP
- [ ] Choose a BSP if/when moving to the WhatsApp Business Platform
