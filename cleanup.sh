ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>

SOURCE_S3_BUCKET="my-stepfunction-ecs-app-dev-source-bucket"
TARGET_S3_BUCKET="my-stepfunction-ecs-app-dev-target-bucket"
ECR_REPO_NAME="my-stepfunction-ecs-app-repo"

aws ecr batch-delete-image --repository-name $ECR_REPO_NAME --image-ids imageTag=latest

aws ecr batch-delete-image --repository-name $ECR_REPO_NAME --image-ids imageTag=untagged

aws s3 rm s3://$SOURCE_S3_BUCKET-$ACCOUNT_NUMBER --recursive
aws s3 rm s3://$TARGET_S3_BUCKET-$ACCOUNT_NUMBER --recursive

cd templates
terraform destroy --auto-approve
cd ..


$SHELL