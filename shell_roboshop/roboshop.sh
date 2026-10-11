
#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SECURITY_GROUP_ID="sg-02775f1c2d5284c4b"

INSTANCES=("MongoDB" "MYSQL" "redis" "cart" "catalogue" "shipping" "rabbitmq" "payment" "dispatch" "frontend")

ZONE_ID=""
DOMAIN_NAME=""

for instance in "${INSTANCES[@]}"
do
    aws ec2 run-instances \
        --image-id "$AMI_ID" \
        --security-group-ids "$SECURITY_GROUP_ID" \
        --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]"
done