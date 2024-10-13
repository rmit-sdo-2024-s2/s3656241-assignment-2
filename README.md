# COSC2759 Assignment 2

## Student details

- Full Name: Samuel Laurance
- Student ID: s3656241

## Solution design
The solution uses a combination of Terraform, Ansible, and Docker to deploy the Foo app. For higher availability, the architecture consists of PostgreSQL and EC2 instances for the Foo application, behind an Application Load Balancer. Terraform sets up the underlying AWS infrastructure, while Ansible automates the server configuration and container deployment.

### Infrastructure
Infrastructure Breakdown:

Client:
Represents the end user gaining access to the Foo online application.
Between the client and the application load balancer (ALB), HTTP traffic (Port 80) is exchanged.

Application Load Balancer (ALB):
Equally divides incoming traffic between the two EC2 instances that are hosting the Foo application.
routes traffic to instances that are in good health, ensuring high availability and scalability.
uses Port 80 to communicate with EC2 instances.

EC2 App Instances:
Two Docker-containerized EC2 instances, each executing the Foo programme.
in charge of handling user requests that come in from the ALB.
exchanges data with the PostgreSQL database to perform backend tasks.

Components:
Foo App in Docker container.
Opens Port 80 to HTTP requests.

EC2 Instance-PostgreSQL:
A specific EC2 instance with a Docker container hosting a PostgreSQL database.
manages all database queries that the Foo programme needs.
The EC2 app instances' internal communication port is open at port 5432.
Snapshot-prod-data.sql was used to initialise the data.

Terraform + GitHub Actions Workflow:
Automates the configuration and setup of infrastructure.
makes the following resources available:
Security Groups S3 Bucket (for state storage) Application Load Balancer (ALB) EC2 instances (App + PostgreSQL)
employs Ansible playbooks to deploy and configure Docker containers.

S3 Bucket for State Management:
Maintains constant tracking of infrastructure modifications by storing Terraform state files.
Supports versioning and state management for the implementation of infrastructure.


## Infrastructure Architecture Diagram

![Infrastructure Architecture](https://github.com/rmit-sdo-2024-s2/s3656241-assignment-2/blob/main/IAD.drawio.png)


#### Key data flows
- User Requests: Forwarded to one of the EC2 instances with the Foo application running on it by the ALB.
- App-to-Database Communication: For backend activities, the Foo application connects with the PostgreSQL instance.


### Deployment process

#### Prerequisites
- AWS account with the required authorisation.
- GitHub repository used to handle workflows for GitHub Actions and the project.
- A pair of SSH keys to get entry to the EC2 instances.

#### Description of the GitHub Actions workflow
The procedure for GitHub Actions automates:

- Terraform provisioning for the S3 bucket, ALB, and EC2 instances.
- To install Docker, pull the Foo application and PostgreSQL images, and launch the containers, use an Ansible playbook.


#### Backup process: deploying from a shell script
For manual deployment, the deploy.sh script offers a backup procedure:

- Installs Terraform on the infrastructure.
- Ansible is used to configure the instances.
- Confirms the operation of the Docker containers.

#### Validating that the app is working
- Access Load Balancer: The application can be reached by using the DNS name of the ALB (output following deployment).

- Check Containers: Make sure the Foo application and PostgreSQL containers are operating by using docker ps.


## Contents of this repo

1. ansible/: Includes the inventory and Ansible playbooks needed to configure EC2 instances.
- app_servers.yml: To set up the application servers using Playbook.
- db_servers.yml: The database servers' configuration playbook.
- inventory.ini: Ansible inventory file that is created dynamically during deployment.
- playbook.yml: The main Ansible playbook via which the configuration tasks are executed.

2. app/: Includes the source code for the Foo Node.js app.
- Dockerfile: Specifies the architecture and containerisation used in the Foo app.
- index.js: The Foo app's primary entry point.
- package.json: Controls the app's dependencies.

3. misc/: Miscellaneous project files.
- how-to-deploy.txt: Instructions on the deployment process.
- snapshot-prod-data.sql: Using a SQL snapshot to set up the PostgreSQL database.
- state-bucket-infra.tf: Configuring the S3 bucket using Terraform to store the state.

4. terraform/: Includes the Terraform configuration files needed to provision the AWS infrastructure.
- main.tf: the primary Terraform file that sets up the S3 bucket, ALB, security groups, and EC2 instances.
- outputs.tf: produces the load balancer's DNS name along with other important data.
- vars.tf: includes definitions for the variables used in the Terraform configuration.
- terraform.tfstate: The Terraform state file keeps track of the resources that are generated by Terraform.
- terraform.tfstate.backup: the Terraform state file backup.

5. .gitignore: Indicates which folders and files (such as sensitive files and node_modules) Git should ignore.

6. deploy.sh: Shell script for automating the deployment process, including server configuration and infrastructure provisioning.

7. README.md: This file contains information about the infrastructure design, deployment procedure, and solution.


