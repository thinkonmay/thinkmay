# Thinkmay Docs

This folder is organized by audience and purpose.

## Main sections

- `product/` — product architecture, user guides, and feature/system docs.
- `employee/` — internal playbooks for support, ops, and staff.
- `marketing/` — strategy, campaigns, SEO, analytics, and research.
- `shared/` — shared assets, snapshots, DB artifacts, and support tools.

## Quick links

### Product
- [Product index](./product/README.md)
- [Technical architecture](./product/architecture/technical_doc.md)
- [Mobile architecture](./product/architecture/mobile_architecture.md)
- [Native app architecture](./product/architecture/native_app.md)
- [Desktop client URL handler](./product/architecture/desktop_client_url_handler.md)
- [Desktop client launch arguments](./product/architecture/desktop_client_launch_arguments.md)
- [User guide](./product/guides/user_doc.md)

### Employee
- [Employee index](./employee/README.md)
- [Employee playbook](./employee/playbooks/employee_doc.md)
- [KVM WRMSR host freeze (Intel nodes)](./employee/playbooks/kvm_wrmsr_host_freeze.md)

### Marketing
- [Marketing index](./marketing/README.md)
- [Marketing playbook](./marketing/strategy/marketing_doc.md)
- [SEO plan](./marketing/seo/seo_growth_implementation_plan.md)
- [Local competitor research](./marketing/research/local_competitors_research_summary.md)
- [Facebook giveaway template](./marketing/campaigns/facebook_giveaway_program_template.md)

### Shared
- [Shared index](./shared/README.md)
- [Images](./shared/assets/images/)
- [Database artifacts](./shared/data/db/)
- [Snapshots](./shared/snapshots/)

## Git hygiene

Curated Markdown reports are intended to be commit-safe after review. Generated captures, raw analytics exports, database dumps, local screenshots, and environment/secrets files are ignored in the repository `.gitignore`.

Before committing, run:

```powershell
git status --short --ignored docs .gitignore
```

Check that only curated docs/scripts/README files are staged, not raw `.xlsx`, `.csv`, `.json`, screenshots, DB dumps, or secrets.
