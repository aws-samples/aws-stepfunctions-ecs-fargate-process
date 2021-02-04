ACCOUNT_NUMBER=<YOUR_ACCOUNT_NUMBER>
REGION=<REGION>
INPUT_S3_BUCKET="my-stepfunction-ecs-app-dev-source-bucket"

APP_ECR_REPO_NAME=my-stepfunction-ecs-app-repo
APP_ECR_REPO_URL=$ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/$APP_ECR_REPO_NAME

# Build the sprintboot Jar
mvn clean package

# Terraform infrastructure apply
cd templates
terraform init
terraform apply --auto-approve

cd ..

docker build -t example/ecsfargateservice . 
docker tag example/ecsfargateservice ${APP_ECR_REPO_URL}:latest

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com
docker push ${APP_ECR_REPO_URL}:latest

#aws ecr list-images --repository-name ${APP_ECR_REPO_URL}


#######
### PUT SAMPLE S3 For the Input S3 bucket
#######

CURRYEAR=`date +"%Y"`
CURRMONTH=`date +"%m"`
CURRDATE=`date +"%d"`

echo $CURRYEAR-$CURRMONTH-$CURRDATE

echo "Creating sample files and will load to S3"
COUNTER=0
NUMBER_OF_FILES=10

EXTN=".txt"
S3_SUB_PATH=$CURRYEAR"/"$CURRMONTH"/"$CURRDATE
echo $S3_SUB_PATH

INPUT_S3_BUCKET_PATH="s3://$INPUT_S3_BUCKET-"$ACCOUNT_NUMBER

cd samples

while [  $COUNTER -lt $NUMBER_OF_FILES ]; do
    FILENAME="Product-"$COUNTER$EXTN
    
    echo "{\"productId\": $COUNTER , \"productName\": \"some Name\", \"productVersion\": \"v$COUNTER\"}" >> $FILENAME

    aws s3 --region $REGION cp $FILENAME $INPUT_S3_BUCKET_PATH/$S3_SUB_PATH/

    echo $FILENAME " samples uploaded into S3 sample bucket"
    let COUNTER=COUNTER+1 
done

cd ..

$SHELL