#!/bin/bash

# Script to import all AWS resources into Terraform state
# This script will help you import existing AWS resources that are not in your .tfstate
# Run this script from the directory containing your Terraform files

set -e

echo "🚀 Starting import of AWS resources into Terraform state..."
echo "⚠️  Make sure you have:"
echo "   - AWS credentials configured"
echo "   - Terraform initialized (terraform init)"
echo "   - Correct AWS region set"
echo ""

# Function to check if resource exists in Terraform state
resource_exists_in_state() {
    local resource_address=$1
    # Escape brackets for grep
    local escaped_address=$(echo "$resource_address" | sed 's/\[/\\[/g; s/\]/\\]/g')
    terraform state list | grep -q "^$escaped_address$"
    return $?
}

# Function to get resource ID by name and type
get_resource_id() {
    local resource_type=$1
    local resource_name=$2
    
    case $resource_type in
        "aws_vpc")
            local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$resource_name" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
            if [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
                echo "$vpc_id"
            else
                echo ""
            fi
            ;;
        "aws_internet_gateway")
            local igw_id=$(aws ec2 describe-internet-gateways --filters "Name=tag:Name,Values=$resource_name" --query 'InternetGateways[0].InternetGatewayId' --output text 2>/dev/null)
            if [ "$igw_id" != "None" ] && [ -n "$igw_id" ]; then
                echo "$igw_id"
            else
                echo ""
            fi
            ;;
        "aws_subnet")
            local subnet_id=$(aws ec2 describe-subnets --filters "Name=tag:Name,Values=$resource_name" --query 'Subnets[0].SubnetId' --output text 2>/dev/null)
            if [ "$subnet_id" != "None" ] && [ -n "$subnet_id" ]; then
                echo "$subnet_id"
            else
                echo ""
            fi
            ;;
        "aws_route_table")
            local rt_id=$(aws ec2 describe-route-tables --filters "Name=tag:Name,Values=$resource_name" --query 'RouteTables[0].RouteTableId' --output text 2>/dev/null)
            if [ "$rt_id" != "None" ] && [ -n "$rt_id" ]; then
                echo "$rt_id"
            else
                echo ""
            fi
            ;;
        "aws_security_group")
            local sg_id=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$resource_name" --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null)
            if [ "$sg_id" != "None" ] && [ -n "$sg_id" ]; then
                echo "$sg_id"
            else
                echo ""
            fi
            ;;
        "aws_lb")
            local lb_arn=$(aws elbv2 describe-load-balancers --names "$resource_name" --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
            if [ "$lb_arn" != "None" ] && [ -n "$lb_arn" ]; then
                echo "$lb_arn"
            else
                echo ""
            fi
            ;;
        "aws_lb_target_group")
            local tg_arn=$(aws elbv2 describe-target-groups --names "$resource_name" --query 'TargetGroups[0].TargetGroupArn' --output text 2>/dev/null)
            if [ "$tg_arn" != "None" ] && [ -n "$tg_arn" ]; then
                echo "$tg_arn"
            else
                echo ""
            fi
            ;;
        "aws_lb_listener")
            # This will be imported by ARN, not by name
            echo "$resource_name"
            ;;
        "aws_lb_listener_rule")
            # This will be imported by ARN, not by name
            echo "$resource_name"
            ;;
        "aws_db_subnet_group")
            local db_sg_name=$(aws rds describe-db-subnet-groups --db-subnet-group-name "$resource_name" --query 'DBSubnetGroups[0].DBSubnetGroupName' --output text 2>/dev/null)
            if [ "$db_sg_name" != "None" ] && [ -n "$db_sg_name" ]; then
                echo "$db_sg_name"
            else
                echo ""
            fi
            ;;
        "aws_db_instance")
            local db_instance_id=$(aws rds describe-db-instances --db-instance-identifier "$resource_name" --query 'DBInstances[0].DBInstanceIdentifier' --output text 2>/dev/null)
            if [ "$db_instance_id" != "None" ] && [ -n "$db_instance_id" ]; then
                echo "$db_instance_id"
            else
                echo ""
            fi
            ;;
        "aws_ecs_cluster")
            # Check if cluster exists by trying to describe it
            if aws ecs describe-clusters --clusters "$resource_name" --query 'clusters[0].status' --output text 2>/dev/null | grep -q "ACTIVE"; then
                echo "$resource_name"
            else
                echo ""
            fi
            ;;
        "aws_service_discovery_private_dns_namespace")
            local namespace_id=$(aws servicediscovery list-namespaces --filters "Name=NAME,Values=$resource_name" --query 'Namespaces[0].Id' --output text 2>/dev/null)
            local vpc_id=$(aws ec2 describe-vpcs --filters "Name=tag:Name,Values=$PROJECT_NAME-vpc" --query 'Vpcs[0].VpcId' --output text 2>/dev/null)
            if [ "$namespace_id" != "None" ] && [ -n "$namespace_id" ] && [ "$vpc_id" != "None" ] && [ -n "$vpc_id" ]; then
                echo "$namespace_id:$vpc_id"
            else
                echo ""
            fi
            ;;
        "aws_service_discovery_service")
            local namespace_id=$(aws servicediscovery list-namespaces --filters "Name=NAME,Values=$PROJECT_NAME.local" --query 'Namespaces[0].Id' --output text 2>/dev/null)
            if [ "$namespace_id" != "None" ] && [ -n "$namespace_id" ]; then
                local service_id=$(aws servicediscovery list-services --filters "Name=NAMESPACE_ID,Values=$namespace_id" --query "Services[?Name=='$resource_name'].Id" --output text 2>/dev/null)
                if [ "$service_id" != "None" ] && [ -n "$service_id" ]; then
                    echo "$service_id"
                else
                    echo ""
                fi
            else
                echo ""
            fi
            ;;
        "aws_ecs_service")
            local cluster_arn=$(aws ecs list-clusters --query 'clusterArns[0]' --output text 2>/dev/null)
            if [ "$cluster_arn" != "None" ] && [ -n "$cluster_arn" ]; then
                local cluster_name=$(echo "$cluster_arn" | sed 's/.*\///')
                echo "$cluster_name/$resource_name"
            else
                echo ""
            fi
            ;;
        "aws_ecs_task_definition")
            local task_def_arn=$(aws ecs describe-task-definition --task-definition "$resource_name" --query 'taskDefinition.taskDefinitionArn' --output text 2>/dev/null)
            if [ "$task_def_arn" != "None" ] && [ -n "$task_def_arn" ]; then
                echo "$task_def_arn"
            else
                echo ""
            fi
            ;;
        "aws_iam_role")
            # Check if role exists
            if aws iam get-role --role-name "$resource_name" >/dev/null 2>&1; then
                echo "$resource_name"
            else
                echo ""
            fi
            ;;
        "aws_iam_role_policy_attachment")
            # This will be imported by role name and policy ARN
            echo "$resource_name"
            ;;
        *)
            echo "Unknown resource type: $resource_type" >&2
            return 1
            ;;
    esac
}

# Function to import resource if not already in state
import_if_not_exists() {
    local resource_address=$1
    local resource_id=$2
    local resource_name=$3
    
    if resource_exists_in_state "$resource_address"; then
        echo "   ✅ $resource_name already imported (skipping)"
    elif [ -n "$resource_id" ] && [ "$resource_id" != "None" ]; then
        echo "   Importing $resource_name: $resource_id"
        terraform import "$resource_address" "$resource_id"
    else
        echo "   ⚠️  $resource_name not found (will be created by Terraform)"
    fi
}

# Get project name from variables or use default
PROJECT_NAME=${PROJECT_NAME:-"rogerio-aws-infrastructure"}
ENVIRONMENT=${ENVIRONMENT:-"dev"}

echo "📋 Using project name: $PROJECT_NAME"
echo "📋 Using environment: $ENVIRONMENT"
echo ""

# Import VPC
echo "🔍 Importing VPC..."
VPC_ID=$(get_resource_id "aws_vpc" "$PROJECT_NAME-vpc")
import_if_not_exists "aws_vpc.main" "$VPC_ID" "$PROJECT_NAME-vpc"

# Import Internet Gateway
echo "🔍 Importing Internet Gateway..."
IGW_ID=$(get_resource_id "aws_internet_gateway" "$PROJECT_NAME-igw")
import_if_not_exists "aws_internet_gateway.main" "$IGW_ID" "$PROJECT_NAME-igw"

# Import Public Subnets
echo "🔍 Importing Public Subnets..."
for i in {1..2}; do
    SUBNET_NAME="$PROJECT_NAME-public-subnet-$i"
    SUBNET_ID=$(get_resource_id "aws_subnet" "$SUBNET_NAME")
    import_if_not_exists "aws_subnet.public[$(($i-1))]" "$SUBNET_ID" "$SUBNET_NAME"
done

# Import Private Subnets
echo "🔍 Importing Private Subnets..."
for i in {1..2}; do
    SUBNET_NAME="$PROJECT_NAME-private-subnet-$i"
    SUBNET_ID=$(get_resource_id "aws_subnet" "$SUBNET_NAME")
    import_if_not_exists "aws_subnet.private[$(($i-1))]" "$SUBNET_ID" "$SUBNET_NAME"
done

# Import Route Table
echo "🔍 Importing Route Table..."
RT_ID=$(get_resource_id "aws_route_table" "$PROJECT_NAME-public-rt")
import_if_not_exists "aws_route_table.public" "$RT_ID" "$PROJECT_NAME-public-rt"

# Import Route Table Associations
echo "🔍 Importing Route Table Associations..."
# Note: Route table associations don't exist yet, they will be created by Terraform
echo "   ⚠️  Route table associations will be created by Terraform (they don't exist yet)"
# for i in {1..2}; do
#     SUBNET_NAME="$PROJECT_NAME-public-subnet-$i"
#     SUBNET_ID=$(get_resource_id "aws_subnet" "$SUBNET_NAME")
#     if [ "$SUBNET_ID" != "None" ] && [ -n "$SUBNET_ID" ]; then
#         echo "   Importing Route Table Association $i for subnet: $SUBNET_ID"
#         terraform import "aws_route_table_association.public[$(($i-1))]" "$SUBNET_ID/$RT_ID"
#     else
#         echo "   ⚠️  Route Table Association $i not found or already imported"
#     fi
# done

# Import Security Groups
echo "🔍 Importing Security Groups..."
SECURITY_GROUPS=("$PROJECT_NAME-ec2-sg" "$PROJECT_NAME-alb-sg" "$PROJECT_NAME-rds-sg" "$PROJECT_NAME-msg")
SECURITY_GROUP_RESOURCES=("aws_security_group.ec2" "aws_security_group.alb" "aws_security_group.rds" "aws_security_group.microservices")

for i in "${!SECURITY_GROUPS[@]}"; do
    SG_NAME="${SECURITY_GROUPS[$i]}"
    SG_RESOURCE="${SECURITY_GROUP_RESOURCES[$i]}"
    SG_ID=$(get_resource_id "aws_security_group" "$SG_NAME")
    import_if_not_exists "$SG_RESOURCE" "$SG_ID" "$SG_NAME"
done

# Import Load Balancer
echo "🔍 Importing Load Balancer..."
ALB_NAME="rogerio-micro-alb"
ALB_ARN=$(get_resource_id "aws_lb" "$ALB_NAME")
import_if_not_exists "aws_lb.microservices" "$ALB_ARN" "$ALB_NAME"

# Import Target Groups
echo "🔍 Importing Target Groups..."
TARGET_GROUPS=("rogerio-user-tg" "rogerio-order-tg")
TARGET_GROUP_RESOURCES=("aws_lb_target_group.user_service" "aws_lb_target_group.order_service")

for i in "${!TARGET_GROUPS[@]}"; do
    TG_NAME="${TARGET_GROUPS[$i]}"
    TG_RESOURCE="${TARGET_GROUP_RESOURCES[$i]}"
    TG_ARN=$(get_resource_id "aws_lb_target_group" "$TG_NAME")
    import_if_not_exists "$TG_RESOURCE" "$TG_ARN" "$TG_NAME"
done

# Import Load Balancer Listener
echo "🔍 Importing Load Balancer Listener..."
if [ -n "$ALB_ARN" ]; then
    LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query 'Listeners[0].ListenerArn' --output text)
    if [ "$LISTENER_ARN" != "None" ] && [ -n "$LISTENER_ARN" ]; then
        echo "   Importing Load Balancer Listener: $LISTENER_ARN"
        import_if_not_exists "aws_lb_listener.microservices" "$LISTENER_ARN" "Load Balancer Listener"
    else
        echo "   ⚠️  Load Balancer Listener not found or already imported"
    fi
fi

# Import Load Balancer Listener Rules
echo "🔍 Importing Load Balancer Listener Rules..."
if [ -n "$LISTENER_ARN" ]; then
    RULES=$(aws elbv2 describe-rules --listener-arn "$LISTENER_ARN" --query 'Rules[?Priority!=`default`].RuleArn' --output text)
    if [ -n "$RULES" ]; then
        RULE_ARNS=($RULES)
        for i in "${!RULE_ARNS[@]}"; do
            RULE_ARN="${RULE_ARNS[$i]}"
            if [ $i -eq 0 ]; then
                echo "   Importing Listener Rule (user service): $RULE_ARN"
                import_if_not_exists "aws_lb_listener_rule.user_service" "$RULE_ARN" "Listener Rule (user service)"
            elif [ $i -eq 1 ]; then
                echo "   Importing Listener Rule (order service): $RULE_ARN"
                import_if_not_exists "aws_lb_listener_rule.order_service" "$RULE_ARN" "Listener Rule (order service)"
            fi
        done
    else
        echo "   ⚠️  Load Balancer Listener Rules not found or already imported"
    fi
fi

# Import RDS Subnet Group
echo "🔍 Importing RDS Subnet Group..."
DB_SUBNET_GROUP_NAME="$PROJECT_NAME-db-subnet-group"
DB_SUBNET_GROUP_ID=$(get_resource_id "aws_db_subnet_group" "$DB_SUBNET_GROUP_NAME")
import_if_not_exists "aws_db_subnet_group.main" "$DB_SUBNET_GROUP_ID" "$DB_SUBNET_GROUP_NAME"

# Import RDS Instance
echo "🔍 Importing RDS Instance..."
DB_INSTANCE_NAME="$PROJECT_NAME-mysql"
DB_INSTANCE_ID=$(get_resource_id "aws_db_instance" "$DB_INSTANCE_NAME")
import_if_not_exists "aws_db_instance.main" "$DB_INSTANCE_ID" "$DB_INSTANCE_NAME"

# Import ECS Cluster
echo "🔍 Importing ECS Cluster..."
ECS_CLUSTER_NAME="$PROJECT_NAME-microservices-cluster"
ECS_CLUSTER_ARN=$(get_resource_id "aws_ecs_cluster" "$ECS_CLUSTER_NAME")
import_if_not_exists "aws_ecs_cluster.microservices" "$ECS_CLUSTER_ARN" "$ECS_CLUSTER_NAME"

# Import Service Discovery Namespace
echo "🔍 Importing Service Discovery Namespace..."
SD_NAMESPACE_NAME="$PROJECT_NAME.local"
SD_NAMESPACE_ID=$(get_resource_id "aws_service_discovery_private_dns_namespace" "$SD_NAMESPACE_NAME")
import_if_not_exists "aws_service_discovery_private_dns_namespace.microservices" "$SD_NAMESPACE_ID" "$SD_NAMESPACE_NAME"

# Import Service Discovery Services
echo "🔍 Importing Service Discovery Services..."
SD_SERVICES=("user-service" "order-service")
SD_SERVICE_RESOURCES=("aws_service_discovery_service.user_service" "aws_service_discovery_service.order_service")

for i in "${!SD_SERVICES[@]}"; do
    SD_SERVICE_NAME="${SD_SERVICES[$i]}"
    SD_SERVICE_RESOURCE="${SD_SERVICE_RESOURCES[$i]}"
    SD_SERVICE_ID=$(get_resource_id "aws_service_discovery_service" "$SD_SERVICE_NAME")
    import_if_not_exists "$SD_SERVICE_RESOURCE" "$SD_SERVICE_ID" "$SD_SERVICE_NAME"
done

# Import ECS Task Definitions
echo "🔍 Importing ECS Task Definitions..."
TASK_DEFINITIONS=("user-service" "order-service")
TASK_DEFINITION_RESOURCES=("aws_ecs_task_definition.user_service" "aws_ecs_task_definition.order_service")

for i in "${!TASK_DEFINITIONS[@]}"; do
    TASK_DEF_NAME="${TASK_DEFINITIONS[$i]}"
    TASK_DEF_RESOURCE="${TASK_DEFINITION_RESOURCES[$i]}"
    TASK_DEF_ARN=$(get_resource_id "aws_ecs_task_definition" "$TASK_DEF_NAME")
    import_if_not_exists "$TASK_DEF_RESOURCE" "$TASK_DEF_ARN" "$TASK_DEF_NAME"
done

# Import ECS Services
echo "🔍 Importing ECS Services..."
if [ -n "$ECS_CLUSTER_ARN" ]; then
    ECS_SERVICES=("user-service" "order-service")
    ECS_SERVICE_RESOURCES=("aws_ecs_service.user_service" "aws_ecs_service.order_service")
    
    for i in "${!ECS_SERVICES[@]}"; do
        ECS_SERVICE_NAME="${ECS_SERVICES[$i]}"
        ECS_SERVICE_RESOURCE="${ECS_SERVICE_RESOURCES[$i]}"
        ECS_SERVICE_ARN=$(get_resource_id "aws_ecs_service" "$ECS_SERVICE_NAME")
        import_if_not_exists "$ECS_SERVICE_RESOURCE" "$ECS_SERVICE_ARN" "$ECS_SERVICE_NAME"
    done
fi

# Import IAM Role
echo "🔍 Importing IAM Role..."
IAM_ROLE_NAME="$PROJECT_NAME-ecs-execution-role"
IAM_ROLE_ARN=$(get_resource_id "aws_iam_role" "$IAM_ROLE_NAME")
import_if_not_exists "aws_iam_role.ecs_execution_role" "$IAM_ROLE_ARN" "$IAM_ROLE_NAME"

# Import IAM Role Policy Attachment
echo "🔍 Importing IAM Role Policy Attachment..."
if [ -n "$IAM_ROLE_NAME" ]; then
    POLICY_ARN="arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
    echo "   Importing IAM Role Policy Attachment: $IAM_ROLE_NAME/$POLICY_ARN"
    import_if_not_exists "aws_iam_role_policy_attachment.ecs_execution_role_policy" "$IAM_ROLE_NAME/$POLICY_ARN" "$IAM_ROLE_NAME Policy Attachment"
else
    echo "   ⚠️  IAM Role Policy Attachment not found or already imported"
fi

echo ""
echo "✅ Import process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Run 'terraform plan' to see what changes Terraform wants to make"
echo "2. Run 'terraform apply' to apply any necessary changes"
echo "3. When ready to destroy, run 'terraform destroy' to remove all resources"
echo ""
echo "⚠️  Important: Make sure to review the plan before applying!" 