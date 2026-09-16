---
description: Rules for writing customer-facing / outbound content (marketing copy, pitches, one-pagers, emails, landing pages)
---

# Content & Marketing Writing Rules

These apply whenever an agent writes prose meant for an outside reader — marketing
copy, pitch docs, one-pagers, landing pages, outbound emails/DMs, ad copy. Content
mistakes are silent: the copy reads fine, ships, and misleads until a human catches it.

## Never fabricate attribution — do not quote the author as if quoting someone else
- NEVER render the document author's (or user's) own words as an EXTERNAL quotation —
  quote marks, pull-quote styling, or "as one user put it" framing that implies an
  outside source said it. Taking the user's conversational phrasing, polishing it, and
  presenting it as a testimonial or third-party quote is fabricated attribution.
- Fold first-person points into plain authorial prose instead. A quotation mark is a
  claim that a specific named/implied source actually said those words — only use it
  when that is literally true and sourced.
- Pattern to flag: pull-quotes, testimonials, or "someone said X" blocks whose actual
  origin is the author's own draft text or the user's chat messages. Past failure: a
  one-pager styled the user's own edited words as an outside quotation; the author was
  quoting himself as if quoting a customer, and the user had to catch it.

## Preserve a told story/argument — ask before condensing
- When condensing a user-told story, argument, or example for length, PRESERVE enough
  context that it stays intelligible and stays attached to the point it was making.
  Over-abbreviation that garbles the meaning or reattaches it to the wrong point is a
  content bug, not an edit.
- When a cut would materially change what a passage says, CHECK WITH THE USER BEFORE
  condensing — not after it ships. A shorter version that says something different is
  worse than a longer one that says the right thing.
- Pattern to flag: a user-supplied narrative or argument compressed to a fragment that
  no longer carries its original meaning, or moved next to an unrelated claim.

## Don't state unshipped features as present-tense fact
- NEVER write a capability as a present-tense, already-shipped claim unless it is
  verified against the ACTUAL implementation — not the roadmap, not the intent, not a
  sibling doc. When the copy and the code disagree, the code wins.
- Before writing any concrete product claim in present tense, confirm it against the
  source of truth (the code, the shipped build, or the living capabilities doc). Flag
  anything aspirational as "planned"/"coming", never as done.
- Pattern to flag: a pitch/landing page asserting a guard-rail, limit, or feature as
  live while the same project's own to-build list (or the code) says it is unbuilt.
  Past failure: a pitch page sold a per-link data cap that "bounces back before the
  radio keys" as shipped, while the code had no such user-facing cap and the page's own
  backlog listed it as unbuilt — the page contradicted itself.
