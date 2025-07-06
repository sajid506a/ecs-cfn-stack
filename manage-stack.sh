#!/bin/bash

# CloudFormation stack management script

# Default values
STACK_NAME="nginx-ecs-stack"
TEMPLATE_FILE="ecs-cloudformation.json"
ENVIRONMENT="dev"
PROJECT="nginx-demo"
OWNER="admin"
REGION="us-east-1"

# Help function
show_help() {
    echo "Usage: $0 [options] <action>"
    echo "Actions:"
    echo "  create    Create a new stack"
    echo "  update    Update an existing stack"
    echo "  delete    Delete an existing stack"
    echo "Options:"
    echo "  -n, --name         Stack name (default: $STACK_NAME)"
    echo "  -t, --template     Template file path (default: $TEMPLATE_FILE)"
    echo "  -e, --environment  Environment name (default: $ENVIRONMENT)"
    echo "  -p, --project      Project name (default: $PROJECT)"
    echo "  -o, --owner        Owner name (default: $OWNER)"
    echo "  -r, --region       AWS region (default: $REGION)"
    echo "  -h, --help         Show this help message"
    exit 1
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        create|update|delete)
            ACTION=$1
            shift
            ;;
        -n|--name)
            STACK_NAME=$2
            shift 2
            ;;
        -t|--template)
            TEMPLATE_FILE=$2
            shift 2
            ;;
        -e|--environment)
            ENVIRONMENT=$2
            shift 2
            ;;
        -p|--project)
            PROJECT=$2
            shift 2
            ;;
        -o|--owner)
            OWNER=$2
            shift 2
            ;;
        -r|--region)
            REGION=$2
            shift 2
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            ;;
    esac
done

# Validate required arguments
if [ -z "$ACTION" ]; then
    echo "Error: Action is required"
    show_help
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file '$TEMPLATE_FILE' not found"
    exit 1
fi

# Validate AWS CLI installation
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed"
    exit 1
fi

# Function to wait for stack operation to complete
wait_for_stack() {
    local stack_name=$1
    local wait_cmd=$2
    
    echo "Waiting for stack operation to complete..."
    if aws cloudformation wait $wait_cmd --stack-name $stack_name --region $REGION; then
        echo "Stack operation completed successfully"
    else
        echo "Stack operation failed. Check AWS Console for details."
        exit 1
    fi
}

# Function to check if stack exists
stack_exists() {
    aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &> /dev/null
    return $?
}

# Main logic
case $ACTION in
    create)
        if stack_exists; then
            echo "Error: Stack '$STACK_NAME' already exists"
            exit 1
        fi
        
        echo "Creating stack '$STACK_NAME'..."
        aws cloudformation create-stack \
            --stack-name $STACK_NAME \
            --template-body file://$TEMPLATE_FILE \
            --parameters \
                ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT \
                ParameterKey=Project,ParameterValue=$PROJECT \
                ParameterKey=Owner,ParameterValue=$OWNER \
            --capabilities CAPABILITY_NAMED_IAM \
            --region $REGION
        
        wait_for_stack $STACK_NAME "stack-create-complete"
        ;;
        
    update)
        if ! stack_exists; then
            echo "Error: Stack '$STACK_NAME' does not exist"
            exit 1
        fi
        
        echo "Updating stack '$STACK_NAME'..."
        aws cloudformation update-stack \
            --stack-name $STACK_NAME \
            --template-body file://$TEMPLATE_FILE \
            --parameters \
                ParameterKey=EnvironmentName,ParameterValue=$ENVIRONMENT \
                ParameterKey=Project,ParameterValue=$PROJECT \
                ParameterKey=Owner,ParameterValue=$OWNER \
            --capabilities CAPABILITY_NAMED_IAM \
            --region $REGION
        
        wait_for_stack $STACK_NAME "stack-update-complete"
        ;;
        
    delete)
        if ! stack_exists; then
            echo "Error: Stack '$STACK_NAME' does not exist"
            exit 1
        fi
        
        echo "Deleting stack '$STACK_NAME'..."
        aws cloudformation delete-stack \
            --stack-name $STACK_NAME \
            --region $REGION
        
        wait_for_stack $STACK_NAME "stack-delete-complete"
        ;;
        
    *)
        echo "Error: Invalid action '$ACTION'"
        show_help
        ;;
esac

# Display stack outputs after create/update
if [ "$ACTION" = "create" ] || [ "$ACTION" = "update" ]; then
    echo "\nStack outputs:"
    aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --query 'Stacks[0].Outputs[*].[OutputKey,OutputValue]' \
        --output table \
        --region $REGION
fi