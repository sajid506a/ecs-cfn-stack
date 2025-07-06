# AWS CloudFormation Stack Manager

This project provides a Bash script to manage an Amazon ECS Fargate stack running NGINX using AWS CloudFormation. The script simplifies creating, updating, and deleting stacks with configurable parameters.

---

##  Files

- `ecs-cloudformation.json`: CloudFormation template for deploying the ECS Fargate infrastructure.
- `manage-stack.sh`: Shell script to manage the stack.
- `README.md`: Documentation.

---

## Prerequisites

- **AWS CLI** installed and configured
- IAM permissions to deploy CloudFormation stacks and manage related AWS resources

---

## Script Usage

```bash
./manage-stack.sh [options] <action>
Actions
create – Create a new CloudFormation stack

update – Update an existing stack

delete – Delete an existing stack

Options
Option	Description	Default
-n, --name	Stack name	nginx-ecs-stack
-t, --template	Path to CloudFormation template	ecs-cloudformation.json
-e, --environment	Environment name (e.g., dev, prod)	dev
-p, --project	Project name for tagging	nginx-demo
-o, --owner	Owner or contact name/email	admin
-r, --region	AWS region	us-east-1
-h, --help	Show help message	


./manage-stack.sh create
Create a stack for the prod environment in us-west-2

./manage-stack.sh create \
  --name nginx-prod-stack \
  --environment prod \
  --project nginx-web \
  --owner devops@example.com \
  --region us-west-2
Update an existing stack using a custom template

./manage-stack.sh update \
  --template custom-template.json \
  --project updated-nginx \
  --environment staging
Delete an existing stack

./manage-stack.sh delete --name nginx-prod-stack
 Show help menu

./manage-stack.sh --help


 Cleanup
To delete all resources created by the stack:


./manage-stack.sh delete

aws ecs list-tasks \
  --cluster nginx-cluster
aws ecs list-tasks --cluster nginx-cluster
aws ecs execute-command \
  --cluster nginx-cluster \
  --task <TASK_ID> \
  --container nginx \
  --command "/bin/sh" \
  --interactive
You can get the TASK_ID using:
aws ecs execute-command --cluster nginx-cluster --task <TASK_ID> --container nginx --command "/bin/sh" --interactive


