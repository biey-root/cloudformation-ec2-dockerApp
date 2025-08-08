# DevOps Assignment — Sample

## Architecture Diagram

```
+-------------------+         +-------------------+
|    Home Network   |         |   AWS VPC         |
| (Your Home IP)    |         | 10.0.0.0/16       |
+-------------------+         +-------------------+
         |                             |
         | SSH (from HomeIP only)      |
         v                             v
+-------------------+         +-------------------+
|   Bastion Host    |<------->|  Public Subnet    |
| Amazon Linux 2    |         | 10.0.1.0/24       |
| t3.micro          |         +-------------------+
+-------------------+                |
         |                           |
         | SSH Tunnel                |
         v                           v
+-------------------+         +-------------------+
|   App EC2         |<------->|  Private Subnet   |
| Amazon Linux 2    |         | 10.0.2.0/24       |
| t3.micro + Docker |         +-------------------+
| nginxdemos/hello  |                |
+-------------------+                |
         |                           |
         | S3 API                    |
         v                           v
+-------------------+         +-------------------+
|   S3 Log Bucket   |         |  NAT Instance     |
| Versioning ON     |         | (optional, stopped|
| Public Blocked    |         | by default)       |
+-------------------+         +-------------------+
```

## Deploy Instructions

1. **Clone this repo and cd into it.**

2. **Deploy the stack:**
   ```sh
   aws cloudformation deploy \
     --template-file cloudformation/main.yaml \
     --stack-name devops-interview-stack \
     --capabilities CAPABILITY_NAMED_IAM \
     --parameter-overrides \
       KeyName=<your-keypair> \
       HomeIP=<your-home-ip-cidr> \
       # (add other parameters if you wish to override defaults)
   ```

3. **Get Outputs:**
   ```sh
   aws cloudformation describe-stacks --stack-name devops-interview-stack \
     --query "Stacks[0].Outputs"
   ```
   - BastionPublicIP
   - AppPrivateIP
   - S3BucketName

## Access the App via SSH Tunnel

1. **SSH to Bastion and create tunnel:**
   ```sh
   ssh -i <key.pem> -L 8080:<APP_PRIVATE_IP>:80 ec2-user@<BASTION_PUBLIC_IP>
   ```
   Replace `<key.pem>`, `<APP_PRIVATE_IP>`, and `<BASTION_PUBLIC_IP>` with your values from stack outputs.

2. **Test the app:**
   - Open [http://localhost:8080](http://localhost:8080) in your browser.
   - You should see the Nginx Hello World page.

## Design & Security Decisions

- **Principle of Least Privilege:**  
  - Bastion SSH allowed only from your HomeIP.
  - App EC2 only accessible from Bastion (SG restricts inbound).
  - S3 bucket blocks all public access, versioning enabled.
  - IAM role for app EC2 allows only minimal S3 actions.
- **Free Tier:**  
  - All EC2 instances are t3.micro.
  - No NAT Gateway (uses NAT instance, stopped by default).
- **Resilience:**  
  - App runs in Docker container with `restart: unless-stopped`.
- **No custom app code:**  
  - Uses `nginxdemos/hello` for simplicity.

## Cleanup Instructions

To delete all resources and avoid charges:
```sh
aws cloudformation delete-stack --stack-name devops-interview-stack
```

## Repo Structure

```
.
├── cloudformation/
│   └── main.yaml
├── app/
│   └── (no code needed, uses nginxdemos/hello)
├── scripts/
│   ├── app-userdata.sh
│   └── verify-ssh-tunnel.md
├── diagrams/
│   └── architecture-ascii.txt
└── README.md
```

## Quick Reference

- **Deploy:** See above.
- **SSH Tunnel:** See above.
- **Test URL:** [http://localhost:8080](http://localhost:8080)
- **Teardown:** See above.

---

**For more details, see comments in `cloudformation/main.yaml` and
