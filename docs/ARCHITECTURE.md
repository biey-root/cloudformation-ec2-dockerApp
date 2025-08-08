# Infrastructure Architecture

## Overview

This document describes the detailed architecture of the DevOps Interview Assignment infrastructure, including network design, security considerations, and component interactions.

## Network Architecture

### VPC Design

```
                    Internet
                       |
                Internet Gateway
                       |
                ┌─────────────┐
                │  Public     │
                │  Subnet     │
                │ 10.0.1.0/24 │
                │             │
                │ ┌─────────┐ │
                │ │ Bastion │ │
                │ │  Host   │ │
                │ └─────────┘ │
                │             │
                │ ┌─────────┐ │
                │ │   NAT   │ │
                │ │Instance │ │
                │ └─────────┘ │
                └─────────────┘
                       │
                ┌─────────────┐
                │  Private    │
                │  Subnet     │
                │ 10.0.2.0/24 │
                │             │
                │ ┌─────────┐ │
                │ │   App   │ │
                │ │Instance │ │
                │ └─────────┘ │
                └─────────────┘
```

### Subnet Configuration

| Subnet | CIDR | AZ | Purpose | Route Table |
|--------|------|----|---------|-------------|
| Public | 10.0.1.0/24 | us-east-1a | Bastion Host, NAT Instance | Public RT |
| Private | 10.0.2.0/24 | us-east-1b | Application Instance | Private RT |

### Route Tables

#### Public Route Table
- **Destination**: 0.0.0.0/0
- **Target**: Internet Gateway
- **Purpose**: Internet access for public subnet

#### Private Route Table
- **Destination**: 0.0.0.0/0
- **Target**: NAT Instance
- **Purpose**: Controlled internet access for private subnet

## Security Architecture

### Security Groups

#### Bastion Security Group
```yaml
- Protocol: TCP
- Port: 22
- Source: HomeIP (configurable)
- Purpose: SSH access from specified IP
```

#### App Security Group
```yaml
- Protocol: TCP
- Port: 80
- Source: Bastion Security Group
- Purpose: HTTP access from bastion

- Protocol: TCP
- Port: 22
- Source: Bastion Security Group
- Purpose: SSH access from bastion
```

#### NAT Security Group
```yaml
- Protocol: TCP
- Port: 80
- Source: 10.0.2.0/24
- Purpose: HTTP traffic from private subnet

- Protocol: TCP
- Port: 443
- Source: 10.0.2.0/24
- Purpose: HTTPS traffic from private subnet

- Protocol: TCP
- Port: 22
- Source: 10.0.1.0/24
- Purpose: SSH access from public subnet
```

### IAM Roles

#### App Instance Role
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

#### S3 Access Policy
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::bucket-name",
        "arn:aws:s3:::bucket-name/*"
      ]
    }
  ]
}
```

## Component Details

### Bastion Host

**Purpose**: Secure access point to private resources
**Instance Type**: t2.micro
**OS**: Amazon Linux 2
**Location**: Public subnet
**Access**: SSH from specified IP range

**Configuration**:
- Minimal software installation
- SSH key-based authentication
- Security group restricts access to specified IP

### NAT Instance

**Purpose**: Provide internet access to private subnet
**Instance Type**: t2.micro
**OS**: Amazon Linux 2
**Location**: Public subnet
**Configuration**: Custom NAT setup with iptables

**NAT Configuration**:
```bash
# Enable IP forwarding
echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
sysctl -p

# Configure NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables -A FORWARD -i eth0 -o eth0 -j ACCEPT
```

### Application Instance

**Purpose**: Run containerized web application
**Instance Type**: t2.micro
**OS**: Amazon Linux 2
**Location**: Private subnet
**Software**: Docker, Docker Compose

**Application Stack**:
- Nginx demo web server (nginxdemos/hello)
- Docker containerization
- Health monitoring
- Logging to S3

### S3 Bucket

**Purpose**: Log storage and application data
**Configuration**:
- Versioning enabled
- Public access blocked
- Server-side encryption
- Lifecycle policies (configurable)

## Data Flow

### External Access Flow
```
Internet → Internet Gateway → Public Subnet → Bastion Host → Private Subnet → App Instance
```

### Application Access Flow
```
User → Bastion Host → App Instance → Docker Container → Web Application
```

### Logging Flow
```
App Instance → S3 Bucket (via IAM role)
```

## Monitoring and Logging

### CloudWatch Integration

**Metrics**:
- EC2 instance metrics (CPU, memory, disk, network)
- S3 bucket metrics
- NAT instance metrics

**Logs**:
- Application logs (via CloudWatch Logs)
- Nginx access/error logs
- System logs

### Health Checks

**Application Level**:
- HTTP health check endpoint (/health)
- Docker container status
- Nginx service status

**Infrastructure Level**:
- EC2 instance status checks
- Security group rule validation
- Route table configuration

## Scalability Considerations

### Horizontal Scaling

**Application Tier**:
- Multiple app instances behind load balancer
- Auto Scaling Group for automatic scaling
- Session management (Redis/ElastiCache)

**Database Tier**:
- RDS Multi-AZ deployment
- Read replicas for read scaling
- Connection pooling

### Vertical Scaling

**Instance Upgrades**:
- t2.micro → t2.small → t2.medium
- Memory and CPU optimization
- Storage expansion

## Disaster Recovery

### Backup Strategy

**Data Backup**:
- S3 bucket versioning
- Automated backups to S3
- Cross-region replication

**Infrastructure Backup**:
- CloudFormation templates versioned
- AMI creation for instances
- Configuration management

### Recovery Procedures

**Instance Recovery**:
1. Launch new instance from AMI
2. Restore configuration
3. Update DNS/load balancer
4. Verify application health

**Data Recovery**:
1. Restore from S3 versioning
2. Validate data integrity
3. Update application configuration

## Security Best Practices

### Network Security

1. **Least Privilege**: Minimal required access
2. **Network Segmentation**: Public/private subnet separation
3. **Security Groups**: Restrictive access rules
4. **NACLs**: Additional network layer protection

### Application Security

1. **HTTPS**: SSL/TLS encryption
2. **Security Headers**: XSS, CSRF protection
3. **Input Validation**: Sanitize user inputs
4. **Regular Updates**: Security patches

### Access Control

1. **IAM Roles**: Instance profiles
2. **Key Management**: AWS KMS integration
3. **Audit Logging**: CloudTrail enabled
4. **Multi-Factor Authentication**: For admin access

## Cost Optimization

### Resource Optimization

1. **Instance Types**: Right-sizing based on usage
2. **Reserved Instances**: For predictable workloads
3. **Spot Instances**: For non-critical workloads
4. **Storage Optimization**: S3 lifecycle policies

### Monitoring Costs

1. **CloudWatch**: Basic monitoring included
2. **Cost Alerts**: Budget notifications
3. **Resource Tagging**: Cost allocation
4. **Regular Review**: Monthly cost analysis

## Compliance and Governance

### Data Protection

1. **Encryption**: At rest and in transit
2. **Access Control**: Role-based access
3. **Audit Trail**: Comprehensive logging
4. **Data Classification**: Sensitive data handling

### Regulatory Compliance

1. **GDPR**: Data privacy compliance
2. **SOC 2**: Security controls
3. **ISO 27001**: Information security
4. **HIPAA**: Healthcare data (if applicable)
