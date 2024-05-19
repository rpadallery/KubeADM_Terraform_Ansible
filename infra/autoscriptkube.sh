#!/bin/bash
echo "Executing the ansible playbook!"
echo "-----"

echo "Applying playbook to setup all instances and kubernetes ( except frontend )" 
chmod 400 raphaeliac.pem
ansible-playbook -i inventory.yml ansible-playbook.yml

echo "-----"
echo "Raph's super epic automatisation script"
echo "-----"

export KUBECONFIG=/tmp/kubeconfig/config
echo "KUBECONFIG env var set to config file" 

kubectl apply -f /home/rqph/iac/infra/files/backend.yml
echo "Deployment and SVC applied to cluster" 

echo "-----"


export BACKEND_PORT=$(kubectl get svc | awk '/backend-svc/ {split($5, port, ":"); split(port[2], portNumber, "/"); print portNumber[1]}')
echo The port of your SVC which will be specified to the target group is : $BACKEND_PORT


echo "-----"

worker_0_az=$(aws ec2 describe-instances \
    --filters "Name=tag-key,Values=Name" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[?contains(Tags[?Key==`Name`]|[0].Value, `Worker 0`)].Placement.AvailabilityZone' \
    --output text)

worker_1_az=$(aws ec2 describe-instances \
    --filters "Name=tag-key,Values=Name" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[?contains(Tags[?Key==`Name`]|[0].Value, `Worker 1`)].Placement.AvailabilityZone' \
    --output text)

worker_0_id=$(aws ec2 describe-instances \
    --filters "Name=tag-key,Values=Name" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[?contains(Tags[?Key==`Name`]|[0].Value, `Worker 0`)].InstanceId' \
    --output text)

worker_1_id=$(aws ec2 describe-instances \
    --filters "Name=tag-key,Values=Name" "Name=instance-state-name,Values=running" \
    --query 'Reservations[*].Instances[?contains(Tags[?Key==`Name`]|[0].Value, `Worker 1`)].InstanceId' \
    --output text)

export WORKER_0_AZ=$worker_0_az
export WORKER_1_AZ=$worker_1_az
export WORKER_0_ID=$worker_0_id
export WORKER_1_ID=$worker_1_id
echo "Worker 0 Availability Zone: $WORKER_0_AZ"
echo "Worker 1 Availability Zone: $WORKER_1_AZ"
echo "Worker 0 Instance ID: $WORKER_0_ID"
echo "Worker 1 Instance ID: $WORKER_1_ID"

echo "-----"

target_group_arn=$(aws elbv2 describe-target-groups \
    --query 'TargetGroups[?TargetGroupName==`worker-nodes-target-group`].TargetGroupArn' \
    --output text)

if [ -n "$target_group_arn" ]; then
    export TARGET_GROUP_ARN=$target_group_arn
    echo "Target Group ARN: $TARGET_GROUP_ARN"
    echo "Registering Worker Node 0 to target group..."
    aws elbv2 register-targets --target-group-arn $TARGET_GROUP_ARN --targets "Id=$WORKER_0_ID,Port=$BACKEND_PORT" 
    echo "Worker Nodes successfully registered to the target group."
else
    echo "Target group 'worker-nodes-target-group' not found."
fi

if [ -n "$target_group_arn" ]; then
    export TARGET_GROUP_ARN=$target_group_arn
    echo "Target Group ARN: $TARGET_GROUP_ARN"
    echo "Registering Worker Node 1 to target group..."
    aws elbv2 register-targets --target-group-arn $TARGET_GROUP_ARN --targets "Id=$WORKER_1_ID,Port=$BACKEND_PORT"    
    echo "Worker Nodes successfully registered to the target group."
else
    echo "Target group 'worker-nodes-target-group' not found."
fi

echo "-----"

echo "Describing targets inside the target group..."
target_health=$(aws elbv2 describe-target-health --target-group-arn $TARGET_GROUP_ARN)

echo "-----"

echo "Deregistering targets with port 80 from the target group..."
aws elbv2 deregister-targets --target-group-arn $TARGET_GROUP_ARN --targets "Id=$WORKER_0_ID,Port=80" "Id=$WORKER_1_ID,Port=80"

echo "-----"

echo "Waiting 300 seconds for targets to become healthy..."
sleep 300

echo "-----"

echo "Setting up frontend..."
ansible-playbook -i inventory.yml frontend-playbook.yml

echo "-----"

echo "Frontend setup, thank you for using Raph's super epic automatisation script"
