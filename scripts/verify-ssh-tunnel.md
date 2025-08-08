## How to Access the App via SSH Tunnel

1. **Get Bastion Public IP and App Private IP from CloudFormation outputs.**

2. **Run this SSH command from your local machine:**
   ```sh
   ssh -i <key.pem> -L 8080:<APP_PRIVATE_IP>:80 ec2-user@<BASTION_PUBLIC_IP>
   ```
   - Replace `<key.pem>` with your SSH private key file.
   - Replace `<APP_PRIVATE_IP>` and `<BASTION_PUBLIC_IP>` with values from stack outputs.

3. **Open your browser and visit:**
   ```
   http://localhost:8080
   ```
   - You should see the Nginx Hello World page.

**Note:**  
SSH access to the bastion is restricted to your home IP (parameterized in the stack).