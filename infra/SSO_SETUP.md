# AWS SSO Setup for Terraform

## Why SSO?

Your current credentials in `~/.aws/credentials` include a `aws_session_token`, which means they're temporary and expire after a few hours. This causes Terraform to fail during long-running operations like EKS cluster creation (15+ minutes).

SSO credentials automatically refresh, making them perfect for Terraform.

## Setup Steps

### 1. Remove Temporary Credentials

First, check if your credentials are temporary:

```bash
grep -A 3 "your-profile-name" ~/.aws/credentials
```

If you see `aws_session_token`, they're temporary.

### 2. Configure SSO

```bash
aws configure sso
```

Answer the prompts:
- **SSO session name**: `my-sso` (or any name you prefer)
- **SSO start URL**: Your organization's portal (e.g., `https://d-xxxxxxxxx.awsapps.com/start`)
- **SSO Region**: Where your SSO is configured (e.g., `us-east-1`)
- **SSO registration scopes**: Press Enter for default
- **Account**: Select your AWS account from the list
- **Role**: Select your role (e.g., `account-admin`)
- **CLI default region**: `us-west-2`
- **CLI default output format**: `json`
- **Profile name**: `my-profile` (or any name you prefer)

### 3. Verify SSO Configuration

```bash
# Check that the profile was created in ~/.aws/config
cat ~/.aws/config

# Login to SSO
aws sso login --profile my-profile

# Test it works
aws sts get-caller-identity --profile my-profile
```

### 4. Update terraform.tfvars

```hcl
aws_profile = "my-profile"  # Use your SSO profile name
```

### 5. Workflow Going Forward

```bash
# Before running Terraform
aws sso login --profile my-profile

# Then run Terraform (credentials will auto-refresh)
terraform plan
terraform apply
```

## Difference: SSO vs Temporary Credentials

### Temporary Credentials (Current - ~/.aws/credentials)
```ini
[profile-name]
aws_access_key_id = ASIA...  # Starts with ASIA
aws_secret_access_key = ...
aws_session_token = ...  # This expires!
```
❌ Expires after 1-12 hours  
❌ Can't refresh automatically  
❌ Fails during long Terraform operations  

### SSO (Recommended - ~/.aws/config)
```ini
[profile my-profile]
sso_session = my-sso
sso_account_id = aws_account
sso_role_name = your-role-name
region = us-west-2

[sso-session my-sso]
sso_start_url = https://your-org.awsapps.com/start
sso_region = us-east-1
sso_registration_scopes = sso:account:access
```
✅ Auto-refreshes during operations  
✅ Secure  
✅ Works with long Terraform runs  

## Troubleshooting

### "Session has expired"

```bash
aws sso login --profile my-profile
```

### "Profile not found"

Check that the profile exists:
```bash
cat ~/.aws/config | grep -A 5 "profile my-profile"
```

### Still using temporary credentials?

Make sure you're not setting `AWS_ACCESS_KEY_ID` or other environment variables that override the profile:
```bash
env | grep AWS
```

If you see AWS environment variables, unset them:
```bash
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_PROFILE
```

