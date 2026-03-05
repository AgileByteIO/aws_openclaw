# OpenTofu Multi-Cloud Configuration for OpenClaw

This OpenTofu configuration creates a cloud instance (AWS or Hetzner) with attached storage for an OpenClaw agent machine.

## What This Creates

### AWS (cloud_provider = "aws")
- **EC2 Instance**: t3.medium instance (configurable)
- **Root Volume**: 30GB encrypted GP3 volume
- **Data Volume**: 100GB encrypted GP3 volume
- **Security Group**: Allows SSH (port 22), HTTP (80), and HTTPS (443)

### Hetzner (cloud_provider = "hetzner")
- **HCloud Server**: cx11 instance (configurable)
- **Root Volume**: 30GB volume
- **Data Volume**: 100GB volume
- **Firewall**: Allows SSH (port 22), HTTP (80), and HTTPS (443)

## Prerequisites

1. **Install OpenTofu**:
   ```bash
   # macOS
   brew install opentofu
   
   # Linux
   curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
   chmod +x install-opentofu.sh
   ./install-opentofu.sh
   ```

2. **Configure Cloud Credentials**:

   **For AWS:**
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and default region
   ```
   Or set environment variables:
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   export AWS_DEFAULT_REGION="us-east-1"
   ```

   **For Hetzner:**
   - Create an API token in the Hetzner Cloud Console
   - Set environment variable:
   ```bash
   export HCLOUD_TOKEN="your-hcloud-token"
   ```

3. **SSH Key**:
   - **AWS**: Create a key pair in AWS EC2 Console, download the .pem file
   - **Hetzner**: Use your existing SSH public key content

## Setup Instructions

1. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your values:
   ```bash
   nano terraform.tfvars
   ```
   
   **Choose your cloud provider:**
   ```hcl
   cloud_provider = "aws"    # or "hetzner"
   ```
   
   **IMPORTANT**: Set the required variables for your chosen provider!

3. **Initialize OpenTofu**:
   ```bash
   tofu init
   ```

4. **Review the plan**:
   ```bash
   tofu plan
   ```

5. **Apply the configuration**:
   ```bash
   tofu apply
   ```
   Type `yes` when prompted.

## Usage

After deployment, OpenTofu will output:
- Instance public IP
- Volume IDs

### Connect to Your Instance

**AWS:**
```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<public-ip>
```

**Hetzner:**
```bash
ssh -i ~/.ssh/your-key.pem root@<public-ip>
```

### Data Volume

The installation script formats and mounts the data volume to `/data` automatically and uses it as the OpenClaw agent home.

## Customization

Edit `terraform.tfvars` to customize:

### Common Options
- **cloud_provider**: Choose "aws" or "hetzner"
- **root_volume_size**: Adjust OS disk size
- **data_volume_size**: Adjust data storage size
- **allowed_ssh_cidr**: Restrict SSH access by IP

### AWS Options
- **aws_region**: Deploy to different AWS region
- **instance_type**: Change to t3.large, t3.xlarge, etc.
- **vpc_id / subnet_id**: Deploy into a non-default VPC (set both values)

### Hetzner Options
- **hcloud_server_type**: Change to cpx31, cax11, etc.
- **hcloud_location**: Change to nbg1, hel1, ash

## Clean Up

To destroy all resources:

```bash
tofu destroy
```

## Security Best Practices

1. **Restrict SSH access**: Change `allowed_ssh_cidr` to your specific IP
2. **Use cloud credentials securely**: Use IAM roles (AWS) or scoped tokens (Hetzner)
3. **Enable monitoring**: Add cloud monitoring for the instance
4. **Regular updates**: Keep OS and packages up to date
5. **Backup strategy**: Configure volume snapshots

## Cost Estimate

### AWS (us-east-1)
- t3.medium instance: ~$30/month
- 30GB GP3 root volume: ~$2.40/month
- 100GB GP3 data volume: ~$8/month
- **Total**: ~$40/month

### Hetzner (fsn1)
- cx11 instance: ~$4/month
- 30GB volume: ~$1.50/month
- 100GB volume: ~$5/month
- **Total**: ~$10/month

## Troubleshooting

- **Permission denied**: Check key file permissions (`chmod 400`)
- **Connection timeout**: Verify security group/firewall rules and IP address
- **OpenClaw CLI not found**: Re-run `/tmp/install-openclaw.sh` or log out/in to refresh the shell PATH
- **AWS: No default VPC**: Set `vpc_id` and `subnet_id` in `terraform.tfvars`
- **Hetzner: Auth error**: Verify `HCLOUD_TOKEN` is set correctly
