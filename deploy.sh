#!/bin/bash
#
# Deploy Foo app - see README.md
#

# Step 1: Initialize and apply Terraform to provision infrastructure
echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve

# Step 2: Get EC2 instance IPs from Terraform outputs
echo "Fetching EC2 instance IP addresses..."
app_instance_ip=$(terraform output -raw app_instance_public_ip)
db_instance_ip=$(terraform output -raw db_instance_public_ip)

# Step 3: Create an Ansible inventory file
echo "Creating Ansible inventory..."
cat <<EOF > inventory.ini
[app_servers]
$app_instance_ip ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-key.pem

[db_servers]
$db_instance_ip ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/your-key.pem
EOF

# Step 4: Run the Ansible playbook to configure the instances
echo "Running Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml

# Step 5: Verify containers are running
echo "Verifying Foo app and PostgreSQL containers are running..."
ssh -i ~/.ssh/your-key.pem ec2-user@$app_instance_ip 'docker ps | grep foo_app' && echo "Foo app is running"
ssh -i ~/.ssh/your-key.pem ec2-user@$db_instance_ip 'docker ps | grep postgres_db' && echo "PostgreSQL is running"

echo "Deployment completed!"
