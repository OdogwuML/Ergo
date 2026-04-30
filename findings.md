# findings.md — Research, Discoveries & Constraints

---

## Discovery Answers

1. **North Star:** A system where landlords can track rent payments across all their buildings, and tenants can make/view their payments.
2. **Integrations:** Interswitch (payments), Resend (email), Termii (SMS). All Nigeria-friendly.
3. **Source of Truth:** Supabase (PostgreSQL).
4. **Delivery Payload:** Web app hosted on Vercel. Landlords can export reports (PDF/Excel). Backend in Golang.
5. **Behavioral Rules:**
   - Tenants cannot see other tenants' payment status
   - Automatic late-payment reminders (email + SMS)
   - Single currency: Naira (₦)
   - Landlords cannot edit past payment records

---

## Research: Go SDK Availability

### Interswitch
- We are using Web Checkout and Category 8 APIs.
- **Decision:** Proceeding with "Option B" (Central Escrow + Category 3 Payouts) since direct split payments via Web Checkout require manual activation.
- Supports: transactions, customers, plans, dedicated virtual accounts
- Amounts usually in **kobo** (subunit) — multiply by 100
- Webhook support for real-time payment status updates

### Supabase
- Official community SDK: `supabase-community/supabase-go`
- Supports: PostgREST, GoTrue (auth), Storage, Realtime, Edge Functions
- Alternative: `nedpals/supabase-go` (unofficial, simpler API)

### Resend
- Official SDK: `resend/resend-go/v3`
- Supports: To, CC, BCC, HTML/text content, attachments
- Free tier: 3,000 emails/month

### Termii
- Community SDK: `Uchencho/go-termii`
- Nigerian company, affordable (~₦4/SMS)
- Supports: SMS sending, OTP verification

---

## Constraints & Gotchas

- Interswitch amounts might be in **kobo** — always check and multiply naira by 100 before sending
- Supabase Go SDK docs are limited for complex operations (joins, functions)
- Vercel primarily supports serverless functions — Go backend may need to be deployed separately (e.g., Railway, Render) or as Vercel serverless Go functions
- Termii is pay-as-you-go, no true free tier
