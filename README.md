# Tavelya

A world of finds. One destination. Ebooks, audiobooks and courses, plus an admin panel and an affiliate platform. Static pages that talk to Supabase.

## Files
| File | What it is |
|---|---|
| `index.html` | The store, including its own full-page Sign in / Create account / Reset password screen (opens when you tap Sign in) |
| `admin.html` | Admin panel (needs an admin account) |
| `affiliate.html` | Affiliate landing page, sign in / apply, dashboard, marketplace, payouts, messages, profile |
| `config.js` | Not required. The Supabase URL and publishable key are built into each page |
| `schema.sql` | Database tables, security rules and signup trigger. Run once in Supabase |
| `terms.html`, `privacy.html`, `refund.html`, `cookies.html`, `affiliate-terms.html`, `about.html`, `faq.html`, `404.html` | Info and policy pages |
| `assets/` | Logos and favicon |

## Set up (in this order)
1. **Supabase > SQL Editor > New query**: paste all of `schema.sql` and run it.
2. **Supabase > Authentication > URL Configuration**: set Site URL to your live address (for example `https://yourusername.github.io/tavelya/`) and add it to Redirect URLs.
3. **Upload every file to the GitHub repo root** (keep `assets/`), then Settings > Pages > Deploy from branch > `main` / root.
4. **Create your admin account**: open `affiliate.html`, apply with your own email, confirm the email if asked. Then in the SQL Editor run the last (commented) line of `schema.sql` with your email, to set `type='admin'`. Now `admin.html` will let you in.
5. In the admin, add departments, products and banners. The store updates from them.

Email confirmation: Supabase's built-in email sender is limited to a few emails per hour. For launch, set up a custom SMTP sender (Authentication > Emails), or turn off "Confirm email" while testing.

## Payments (set up in the admin)
1. Run the new **PAYMENTS** section of `schema.sql` (or the whole file again; it is safe to re-run).
2. Admin > Payments: set the checkout button label, and add manual methods (bank transfer, mobile money, PayPal address). Their instructions are shown to customers on the checkout page.
3. Admin > Products > Edit: paste a payment link (Stripe, Paystack, Flutterwave, PayPal) in **Checkout link**, and the private download or course link in **Access link**. The access link is stored in a separate protected table and is only given to a customer whose order is marked paid.
4. A customer taps Buy now, signs in, chooses how to pay, and an order is created. Manual payments arrive as "awaiting confirmation" with the customer's reference; online payments arrive as "pending".
5. Admin > Orders: check the payment in your bank or Stripe/Paystack, then **Mark paid**. The item then shows an Open button in the customer's **My library**.
Orders also record the affiliate referral code (`ref_code`). The affiliate dashboard does not read orders yet.
Prices are shown in dollars.

## How the pages are linked
- **Admin > store**: products, departments, banners and the store color are saved to the `site_data` table. The store reads them (first visit reloads once to apply changes).
- **Affiliate signups**: create a `pending` profile. The admin approves or rejects it in Accounts. Only approved affiliates can enter the dashboard.
- **Commission rates**: set per department in the admin and shown in the affiliate marketplace (a custom rate on an account overrides them).
- **Reviews**: signed-in customers post from a product page. The admin can hide or delete them. Affiliates read published reviews in the marketplace.
- **Messages**: sent from the admin, shown in the affiliate Messages tab.
- **Security**: all rules are in `schema.sql` (Row Level Security). Nobody can sign up as admin. Never put the secret / service_role key in this repository.

## Not built yet (next jobs)
- **Automatic payment confirmation.** Payments are confirmed by the admin by hand (Orders > Mark paid). To confirm automatically, add Stripe or Paystack webhooks (a Supabase Edge Function) that set the order to paid.
- **Affiliate tracking**: the store saves `?ref=CODE` to `localStorage.tv_ref`. Record referrals and orders on the server, calculate commission, reverse it on refunds, and feed the affiliate dashboard (it shows zeros until then).
- **Reader, audio player and a "My Library" page** with saved progress.
- Translations of product text in French and Spanish.
- Store announcement bar and store name (saved in admin Settings but not shown yet).
- Deleting accounts permanently (the admin marks them rejected).

## Before launch
- Have a lawyer review the policy pages. The refund terms and commission rates are defaults.
- Add a support contact channel; none is published.
- If the Supabase library version in the pages fails to load, update the version in the `<script src=...supabase-js@...>` tag.
