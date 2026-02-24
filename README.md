# OpenTofu AWS EC2 Configuration for OpenClaw Machine

This OpenTofu configuration creates an AWS EC2 instance with attached storage for an OpenClaw agent machine.

## What This Creates

- **EC2 Instance**: t3.medium instance (configurable)
- **Root Volume**: 30GB encrypted GP3 volume
- **Data Volume**: 100GB encrypted GP3 volume (attached as /dev/sdf)
- **Security Group**: Allows SSH (port 22), HTTP (80), and HTTPS (443)

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

2. **Configure AWS Credentials**:
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

3. **Create an SSH Key Pair in AWS**:
   - Go to EC2 Console → Key Pairs → Create Key Pair
   - Download the .pem file and save it to `~/.ssh/`
   - Set permissions: `chmod 400 ~/.ssh/your-key.pem`

## Setup Instructions

1. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. **Edit terraform.tfvars** with your values:
   ```bash
   nano terraform.tfvars
   ```
   
   **IMPORTANT**: Set your `key_pair_name` and restrict `allowed_ssh_cidr` to your IP!

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
- SSH connection string
- Volume IDs

### Connect to Your Instance

```bash
ssh -i ~/.ssh/your-key.pem ubuntu@<public-ip>
```

### Data Volume

The installation script formats and mounts the data volume to `/data` automatically and uses it as the OpenClaw agent home.

## Customization

Edit `terraform.tfvars` to customize:
- **instance_type**: Change to t3.large, t3.xlarge, etc.
- **root_volume_size**: Adjust OS disk size
- **data_volume_size**: Adjust data storage size
- **aws_region**: Deploy to different AWS region
- **allowed_ssh_cidr**: Restrict SSH access by IP
- **vpc_id / subnet_id**: Deploy into a non-default VPC (set both values)

## Clean Up

To destroy all resources:

```bash
tofu destroy
```

## Security Best Practices

1. **Restrict SSH access**: Change `allowed_ssh_cidr` to your specific IP
2. **Use IAM roles**: Consider attaching IAM roles instead of embedding credentials
3. **Enable CloudWatch**: Add monitoring for the instance
4. **Regular updates**: Keep AMI and packages up to date
5. **Backup strategy**: Configure EBS snapshots

## Cost Estimate

Approximate monthly costs (us-east-1):
- t3.medium instance: ~$30/month
- 30GB GP3 root volume: ~$2.40/month
- 100GB GP3 data volume: ~$8/month
- **Total**: ~$40/month (plus data transfer costs)

## Troubleshooting

- **No SSH key pair**: Create one in AWS EC2 Console first
- **Permission denied**: Check key file permissions (`chmod 400`)
- **Connection timeout**: Verify security group and IP address
- **Volume not visible**: Check `lsblk` for the device name (might be xvdf instead of sdf)
- **OpenClaw CLI not found**: Re-run `/tmp/install-openclaw.sh` or log out/in to refresh the shell PATH
- **No default VPC**: Set `vpc_id` and `subnet_id` in `terraform.tfvars`
