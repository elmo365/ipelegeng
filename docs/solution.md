# Solution

Ipelege is a single mobile marketplace where customers find, book and pay
verified informal service providers across every category they need — and where
providers reach customers without paying anything until real work arrives.

Four things make it work.

## 1. Breadth by design

The platform launches multi-category rather than growing into it, because the
differentiator against single-purpose incumbents is one app covering a
household's real needs. Launching narrow and expanding later forfeits the entire
thesis, since a single-category app is directly comparable to — and worse
resourced than — the incumbent in that category.

Categories are chosen so they feed each other: renting generates moving, events
generate catering and hire. See [categories](categories.md).

## 2. Providers only pay for outcomes

Providers load a wallet balance and a commission is deducted per completed
booking. No bookings, no cost.

Consumers are never charged a platform fee, in any category, on any transaction.
This is a firm constraint, not a launch promotion.

Where a booking model does not fit — as with property rentals — the supply side
still pays: landlords pay per listing. See [monetization](monetization.md).

## 3. Trust is the product

Verified providers, KYC on landlords and properties, live GPS tracking on rides.

Facebook groups and word of mouth already have reach; what they lack is
accountability. Verification is the thing being sold, and it is why a landlord
will pay to list here rather than posting free to a Facebook group.

Live GPS tracking is treated as a launch requirement for rides, not a later
addition — rider safety is the precondition for anyone endorsing the platform.
The intent is to assemble this from open-source components rather than build
tracking infrastructure from scratch.

## 4. Payments meet people where they already are

Orange Money at launch via their published API, with MyZaka and Smega behind a
provider abstraction for phase two. Cards run through an external gateway so no
card data ever touches the platform. See [payments](payments.md).
