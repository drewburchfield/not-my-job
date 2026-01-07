---
name: 1password-management
description: Use when interacting with 1Password CLI (op) to create, read, update, or manage credentials. Provides proper syntax, field types, best practices, and common pitfall avoidance.
---

# 1Password CLI Management

Use this skill when working with 1Password CLI (`op`) for credential management.

## When to Use This Skill

- Creating new items in 1Password vaults
- Reading/retrieving credentials from 1Password
- Updating existing 1Password items
- Managing developer secrets and API keys
- Organizing credentials with tags and categories

## Critical Rules

### 1. ALWAYS Quote Field Assignments

**WRONG:**
```bash
op item create API_KEY[password]=abc123
```

**CORRECT:**
```bash
op item create "API_KEY[password]=abc123"
```

**Why:** Shell glob expansion will break unquoted square brackets

### 2. Use Proper Field Types

| Field Type | Use Case | JSON Type |
|------------|----------|-----------|
| `password` | Hidden/concealed fields (API keys, tokens) | `CONCEALED` |
| `text` | Plain text (usernames, IDs, non-sensitive) | `STRING` |
| `email` | Email addresses | `EMAIL` |
| `url` | Web addresses | `URL` |
| `date` | Dates (format: YYYY-MM-DD) | `DATE` |
| `monthYear` | Month/year (format: YYYYMM or YYYY/MM) | `MONTH_YEAR` |
| `phone` | Phone numbers | `PHONE` |
| `otp` | One-time passwords (otpauth:// URI) | `OTP` |

### 3. Built-in Fields DON'T Need Field Types

**Built-in fields for API Credential category:**
- `username` - Use for usernames/account names
- `notesPlain` - Use for notes (supports multiline)
- `website` - Primary URL for the credential
- `tags` - Comma-separated tags

**WRONG:**
```bash
"username[text]=user@example.com"
```

**CORRECT:**
```bash
"username=user@example.com"
```

### 4. Multiline Notes - Use Literal String

**CORRECT:**
```bash
"notesPlain=Line 1

Line 2
Line 3"
```

**ALSO CORRECT (heredoc):**
```bash
--notes "$(cat <<'EOF'
Line 1
Line 2
Line 3
EOF
)"
```

### 5. Security Best Practices

**Categories for Developer Credentials:**
1. `API Credential` - Best for most API keys, tokens, secrets
2. `Password` - For simple password-only credentials
3. `Secure Note` - For complex structured data
4. `Login` - For web-based authentication

**Tagging Strategy:**
- Use project name as primary tag (e.g., `master_mcp`)
- Add service/vendor tags (e.g., `google`, `slack`, `atlassian`)
- Add purpose tags (e.g., `api`, `oauth`, `database`)
- Add status tags if needed (e.g., `unstable`, `deprecated`)

## Complete Command Patterns

### Pattern 1: Simple API Key

```bash
op item create \
  --category "API Credential" \
  --title "Project - Service Name" \
  --vault "Dev Environments" \
  --tags "project,service,api" \
  "API_KEY[password]=your-secret-key-here" \
  "website[url]=https://console.service.com" \
  "notesPlain=Brief description.

Usage: What this credential is for
Service: Container/service name

To regenerate:
1. Step one
2. Step two"
```

### Pattern 2: OAuth Credentials

```bash
op item create \
  --category "API Credential" \
  --title "Project - OAuth Service" \
  --vault "Dev Environments" \
  --tags "project,oauth,service" \
  "CLIENT_ID[text]=your-client-id" \
  "CLIENT_SECRET[password]=your-client-secret" \
  "email[email]=user@example.com" \
  "website[url]=https://console.service.com/credentials" \
  "notesPlain=OAuth 2.0 credentials.

Services: service-name container
Usage: API access for X, Y, Z
Scopes: scope1, scope2

To regenerate:
1. Visit console URL
2. Create OAuth application
3. Download credentials"
```

### Pattern 3: Database Credentials

```bash
op item create \
  --category "API Credential" \
  --title "Project - Database Name" \
  --vault "Dev Environments" \
  --tags "project,database,postgres" \
  "username[text]=dbuser" \
  "password[password]=secure-db-password" \
  "hostname[text]=localhost" \
  "port[text]=5432" \
  "database[text]=dbname" \
  "website[url]=https://db-admin.example.com" \
  "notesPlain=PostgreSQL database credentials.

Services: db-container, app-container
Usage: Application database

To regenerate password:
./scripts/generate-db-password.sh"
```

### Pattern 4: Multi-field API Credentials

```bash
op item create \
  --category "API Credential" \
  --title "Project - Complex Service" \
  --vault "Dev Environments" \
  --tags "project,service,complex" \
  "username[text]=admin@example.com" \
  "PRIMARY_TOKEN[password]=token-abc-123" \
  "SECONDARY_TOKEN[password]=token-xyz-789" \
  "API_URL[url]=https://api.service.com" \
  "WORKSPACE_ID[text]=ws-12345" \
  "website[url]=https://console.service.com/api" \
  "notesPlain=Multi-credential service access.

Services: service-container on port 8080
Features: Feature 1, Feature 2

Configuration file: configs/service/.env.instance

To regenerate:
1. Login to console
2. Navigate to API section
3. Generate new tokens"
```

## Reading Credentials

### List Items in Vault
```bash
op item list --vault "Dev Environments" --tags "project"
```

### Get Specific Item (concealed by default)
```bash
op item get "master_mcp - Service Name"
```

### Reveal Secrets
```bash
op item get "master_mcp - Service Name" --reveal
```

### Get Specific Field
```bash
op item get "master_mcp - Service Name" --fields API_KEY --reveal
```

### Export as JSON
```bash
op item get "master_mcp - Service Name" --format json
```

## Common Pitfalls & Solutions

### Pitfall 1: Forgetting Quotes
**Error:** `no matches found: API_KEY[password]=...`
**Solution:** Always quote field assignments

### Pitfall 2: Using Field Types on Built-in Fields
**Error:** Creates duplicate fields or unexpected behavior
**Solution:** Only use field types (e.g., `[password]`) for custom fields

### Pitfall 3: Sensitive Data in Command History
**Problem:** Command arguments visible in process list and shell history
**Solution:** For highly sensitive data, use JSON templates:
```bash
# Create template
op item template get "API Credential" > /tmp/item.json

# Edit template file with sensitive data
# Then create from template
op item create --template /tmp/item.json --vault "Dev Environments"
rm /tmp/item.json
```

### Pitfall 4: Wrong Category
**Problem:** Using wrong item category loses structured fields
**Solution:** Use these categories:
- `API Credential` - For API keys, tokens, service credentials
- `Login` - For website logins with username/password
- `Password` - For standalone passwords
- `Secure Note` - For unstructured sensitive information
- `Database` - For database connection credentials

### Pitfall 5: Missing Vault Context
**Problem:** Item created in wrong vault
**Solution:** Always specify `--vault "Vault Name"`

## Metadata Best Practices

### Title Naming Convention
Format: `{project} - {service/purpose}`

Examples:
- `master_mcp - Google Search API`
- `master_mcp - Slack Browser Tokens`
- `myapp - Production Database`
- `myapp - AWS S3 Credentials`

### Notes Template
```
{Brief one-line description}

Services: {container/service names}
Usage: {what this credential enables}
{Optional: Features, configuration, specifics}

{Optional: Pricing, limits, constraints}

To regenerate:
1. {Step by step instructions}
2. {With URLs where possible}
```

### Tag Strategy
1. **Project tag** (required): Identifies which project owns this
2. **Service tag** (recommended): Names the service (google, slack, aws, etc.)
3. **Type tag** (recommended): Purpose (api, oauth, database, etc.)
4. **Status tag** (optional): State (unstable, deprecated, staging, production)

Example: `--tags "master_mcp,google,api,search"`

## Integration with Environment Files

When storing credentials that belong in `.env` files:

1. **Create in 1Password** with structured metadata
2. **Reference in README** how to retrieve:
   ```bash
   # Retrieve from 1Password
   op item get "project - service" --fields API_KEY --reveal
   ```
3. **Use secret references** in scripts:
   ```bash
   # In .env (checked into git)
   API_KEY=op://Dev Environments/master_mcp - Service/API_KEY

   # Run with op run
   op run -- docker-compose up
   ```

## Checklist Before Creating Item

- [ ] Chosen appropriate category (usually "API Credential")
- [ ] Title follows naming convention: `{project} - {service}`
- [ ] Specified correct vault with `--vault`
- [ ] All field assignments are quoted
- [ ] Used correct field types (password for secrets, text for non-sensitive)
- [ ] NOT using field types on built-in fields (username, notesPlain, website)
- [ ] Added comprehensive notes with regeneration instructions
- [ ] Added appropriate tags (project, service, type)
- [ ] Included URLs in website field and relevant custom URL fields

## Advanced: Updating Items

### Add Field to Existing Item
```bash
op item edit "item-name" "NEW_FIELD[password]=value"
```

### Update Existing Field
```bash
op item edit "item-name" "API_KEY[password]=new-value"
```

### Add Tags
```bash
op item edit "item-name" --tags "existing,tags,new-tag"
```

## Quick Reference Card

```bash
# Create API credential
op item create \
  --category "API Credential" \
  --title "{project} - {service}" \
  --vault "Dev Environments" \
  --tags "{project},{service},{type}" \
  "{FIELD_NAME}[password]={secret}" \
  "website[url]={console-url}" \
  "notesPlain={description and regeneration steps}"

# List items
op item list --vault "Dev Environments" --tags "{project}"

# Get item (hidden)
op item get "{project} - {service}"

# Get item (revealed)
op item get "{project} - {service}" --reveal

# Get specific field
op item get "{project} - {service}" --fields {FIELD_NAME} --reveal

# Update field
op item edit "{project} - {service}" "{FIELD_NAME}[password]={new-value}"
```

## Resources

- **Official Docs:** https://developer.1password.com/docs/cli/
- **Item Fields:** https://developer.1password.com/docs/cli/item-fields/
- **Create Items:** https://developer.1password.com/docs/cli/item-create/
- **Secret References:** https://developer.1password.com/docs/cli/secret-references/

## Summary

When working with 1Password CLI:
1. **Always quote** field assignments
2. **Use field types** only for custom fields (not built-in fields)
3. **Choose correct category** (API Credential for most dev credentials)
4. **Include comprehensive notes** with regeneration instructions
5. **Tag appropriately** for easy discovery
6. **Use secret references** for secure environment variable loading
