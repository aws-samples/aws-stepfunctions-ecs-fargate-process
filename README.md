# **Provision AWS infrastructure using Terraform (By HashiCorp): an example of running Amazon ECS tasks on AWS Fargate** 


[AWS Fargate](https://aws.amazon.com/fargate) supports many common container use cases, like running micro-services architecture applications, batch processing, machine learning applications, and migrating on premise applications to the cloud without having to manage servers or clusters of Amazon EC2 instances.AWS customers have a choice of fully managed container services, including [Amazon Elastic Container Service](https://aws.amazon.com/ecs/) (Amazon ECS) and [Amazon Elastic Kubernetes Service](https://aws.amazon.com/ecs/) (Amazon EKS). Both services support a broad array of compute options, have deep integration with other AWS services, and provide the global scale and reliability you’ve come to expect from AWS. For more details to choose between ECS and EKS please refer this [blog](https://aws.amazon.com/blogs/containers/amazon-ecs-vs-amazon-eks-making-sense-of-aws-container-services/). 

With AWS Fargate, you no longer have to provision, configure, or scale clusters of virtual machines to run containers. In this blog, we will use [Amazon Elastic Container Service (ECS)](https://aws.amazon.com/ecs), a highly scalable, high performance container management service that supports Docker containers.Amazon ECS use containers provisioned by Fargate to automatically scale, load balance, and manage scheduling of your containers for availability, providing an easier way to build and operate containerized applications. There are several ‘infrastructure as code’ frameworks available today, to help customers define their infrastructure, such as the [AWS CloudFormation](https://aws.amazon.com/cloudformation/),  [AWS CDK](https://aws.amazon.com/cdk/) or Terraform by [HashiCorp](https://www.hashicorp.com/). In this blog, we will walk you through a use case of running an Amazon ECS Task on AWS Fargate that can be initiated using [AWS Step Functions](https://aws.amazon.com/step-functions). We will use Terraform to model the AWS infrastructure.

[Terraform](https://www.terraform.io/intro/) by [HashiCorp](https://hashicorp.com/), an AWS Partner Network (APN) Advanced Technology Partner and member of the [AWS DevOps Competency](https://aws.amazon.com/solutions/partners/dev-ops/), is an *infrastructure as code* tool similar to AWS CloudFormation that allows you to create, update, and version your Amazon Web Services (AWS) infrastructure. Terraform provide friendly syntax (similar to AWS CloudFormation) along with other features like planning (visibility to see the changes before they actually happen), graphing, create templates to break configurations into smaller chunks to organize, maintain and reusability. We will leverage the capabilities and features of Terraform to build an API based ingestion process into AWS. Let’s get started!

We will provide the Terraform infrastructure definition and the source code for a Java based container application that will read & process the files in the input [AWS S3](https://aws.amazon.com/s3/) bucket. The files will be processed and pushed to an [Amazon Kinesis stream](https://aws.amazon.com/kinesis/). The stream is subscribed with an [Amazon Data Firehose](https://aws.amazon.com/kinesis/data-firehose) which has a target of an output AWS S3 bucket. The java application is containerized using a Dockerfile and the ECS tasks are orchestrated using the [ECS task definition](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-ecs-taskdefinition.html) which are also built using the terraform. 

At a high-level, we will go through the following:

1. Create a simple java application that will read contents of Amazon S3 bucket folder and pushes it to Amazon Kinesis stream. The application code is build using maven.
2. Use HashiCorp Terraform to define the AWS infrastructure resources required for the application.
3. Use terraform commands to plan, apply and destroy (cleanup the infrastructure)
4. The infrastructure builds a new [Amazon VPC](https://aws.amazon.com/vpc/) where the required AWS resources are launched in a logically isolated virtual network that you define. The infrastructure spins up [Amazon SNS](https://aws.amazon.com/sns/),  [NAT Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html#nat-gateway-basics), [S3 Gateway Endpoint](https://docs.aws.amazon.com/vpc/latest/userguide/vpce-gateway.html), [Elastic Network Interface](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-eni.html), [Amazon ECR](https://aws.amazon.com/ecr/), etc.,
5. Provided script inserts sample S3 content files in the input bucket that are needed for the application processing.
6. Navigate to AWS Console, AWS Step Functions and initiate the process. Validate the result in logs and the output in S3 bucket.
7. Cleanup Script, that will clean up the AWS ECR, Amazon S3 input files and destroy AWS resources created by the terraform


The creation of above infrastructure on your account would result in charges beyond free tier. Please see below Pricing section for each individual services’ specific details. Make sure to clean up the built infrastructure to avoid any recurring cost.

![Alt text](aws-ecs-stepfunctions.png?raw=true "ECS Fargate Step Functions")

## Overview of some of the AWS services used in this solution

*  [Amazon Elastic Container Service (ECS)](https://aws.amazon.com/ecs), a highly scalable, high performance container management service that supports Docker containers
* [AWS Fargate](https://aws.amazon.com/fargate) is a serverless compute engine for containers that works with both [Amazon Elastic Container Service (ECS)](https://aws.amazon.com/ecs/) and [Amazon Elastic Kubernetes Service (EKS)](https://aws.amazon.com/eks/). Fargate makes it easy for you to focus on building your applications. Fargate removes the need to provision and manage servers, lets you specify and pay for resources per application, and improves security through application isolation by design.
* [Amazon Kinesis](https://aws.amazon.com/kinesis/) makes it easy to collect, process, and analyze real-time, streaming data so you can get timely insights and react quickly to new information.
* [Amazon Virtual Private Cloud (Amazon VPC)](https://aws.amazon.com/vpc) is a service that lets you launch AWS resources in a logically isolated virtual network that you define. You have complete control over your virtual networking environment, including selection of your own IP address range, creation of subnets, and configuration of route tables and network gateways

## Prerequisites

We will use Docker Containers to deploy the Java application. The following are required to setup your development environment:

1. An AWS Account.
2. Make sure to have Java installed and running on your machine. For instructions, see [Java Development Kit](https://www.oracle.com/java/technologies/javase-downloads.html)
3. [Apache Maven](https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html) – Java application code is built using mvn packages and are deployed using Terraform into AWS
4. Set up Terraform. For steps, see [Terraform downloads](https://www.terraform.io/downloads.html)
5. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cliv2-migration.html) - Make sure to [configure](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) your AWS CLI
6. [Docker](https://www.docker.com/)
    1. [Install Docker](https://www.docker.com/products/docker-desktop) based on your OS.
    2. Make sure the docker daemon/service is running. We will build, tag & push the application code using the provided Dockerfile to the Amazon ECR

## Walk-through of the Solution

At a high-level, here are the steps you will follow to get this solution up and running.

1. [Download](https://github.com/aws-samples/aws-stepfunctions-ecs-fargate-process) the code and perform maven package for the Java lambda code.
2. Run Terraform command to spin up the infrastructure.
3. Once the code is downloaded, please take a moment to see how Terraform provides a similar implementation for spinning up the infrastructure like that of AWS CloudFormation. You may use [Visual Studio Code](https://aws.amazon.com/visualstudiocode/) or your favorite choice of IDE to open the folder (aws-stepfunctions-ecs-fargate-process)
4. The git folder will have these folder 
    1. “templates” - Terraform templates to build the infrastructure 
    2. “src” - Java application source code. 
    3. Dockerfile
    4. “exec.sh” - a shell script that will build the infrastructure, java code and will push to Amazon ECR. Make sure to have Docker running in your machine at this point. Also modify your account number where the application need to deployed, tested.
5. This step is needed if you are running the steps manually and not using the provide “exec.sh” script. Put sample files in the input S3 bucket location - It could be something like “my-stepfunction-ecs-app-dev-source-bucket-<YOUR_ACCOUNTNUMBER>”
6. In AWS Console, navigate to AWS Step Function. Click on “my-stepfunction-ecs-app-ECSTaskStateMachine”. Click “Start Execution” button.
7. Once the Step Function is completed, output of the processed files can be found in “my-stepfunction-ecs-app-dev-target-bucket-<YOUR_ACCOUNTNUMBER>”


**Detailed steps are provided below**

### 1. Deploying the Terraform template to spin up the infrastructure 

Download the code from the  [GitHub](https://github.com/aws-samples/aws-stepfunctions-ecs-fargate-process) location.

`$ git clone https://github.com/aws-samples/aws-stepfunctions-ecs-fargate-process`

Please take a moment to review the code structure as mentioned above in the walkthrough of the solution. 
Provided “exec.sh” script/bash file as part of the code base folder, Make sure to replace **<YOUR_ACCOUNT_NUMBER>, <YOUR_REGION>** with your AWS account number (where you are trying to deploy/run this application) and the **<REGION>** with the AWS region . This will create the infrastructure and pushes the java application into the ECR. Last section on the script also creates sample/dummy input files for the source S3 bucket.


* `$ cd aws-stepfunctions-ecs-fargate-process`
* `$ chmod +x exec.sh`
* `$ ./exec.sh`



### 2. Manual Deployment (Only do if you did not do the above step)

Do this only if you are not executing the above scripts and wanted to perform these steps manually 

**Step 1**: Build java application

* `$ cd aws-stepfunctions-ecs-fargate-process`
* `$ mvn clean package`


**Step 2**: Deploy the infrastructure

* `$ cd templates`
* `$ terraform plan`
* `$ terraform apply --auto-approve`


**Step 3:** Steps to build and push Java application into ECR (my-stepfunction-ecs-app-repo ECR repository created as part of above infrastructure)


* `$ docker build -t example/ecsfargateservice .`
* `$ docker tag example/ecsfargateservice $ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/my-stepfunction-ecs-app-repo:latest`
* `$ aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com`
* `$ docker push $ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/my-stepfunction-ecs-app-repo:latest`


Make sure to update your region and account number above

**Step 4:** Sample S3 files generation to the input bucket


* `$ echo "{\"productId\":"1" , \"productName\": \"some Name\", \"productVersion\": \"v1"}" >> "product_1.txt"`
* `$ aws s3 --region $REGION cp "product_1.txt" my-stepfunction-ecs-app-dev-source-bucket-<YOUR_ACCOUNTNUMBER>`


Note: exec.sh script has logic to create multiple files to validate. Above provided will create 1 sample file

### 3. Stack Verification

Once the preceding Terraform commands complete successfully, take a moment to identify the major components that are deployed in AWS.

* Amazon VPC
    * VPC - my-stepfunction-ecs-app-VPC
    * Subnets
        * Public subnet - my-stepfunction-ecs-app-public-subnet1
        * Private subnet - my-stepfunction-ecs-app-private-subnet1
    * Internet gateway - my-stepfunction-ecs-app-VPC
    * NAT Gateway - my-stepfunction-ecs-app-NATGateway
    * Elastic IP - my-stepfunction-ecs-app-elastic-ip
    * VPC Endpoint
* AWS Step Functions
    * my-stepfunction-ecs-app-ECSTaskStateMachine
* Amazon ECS
    * Cluster - my-stepfunction-ecs-app-ECSCluster
    * Task Definition - my-stepfunction-ecs-app-ECSTaskDefinition
* Amazon Kinesis 
    * Data Stream - my-stepfunction-ecs-app-stream
    * Delivery stream – my-stepfunction-ecs-app-firehose-delivery-stream - notice the source (kinesis stream) and the target output S3 bucket
* S3
    * my-stepfunction-ecs-app-dev-source-bucket-<YOUR_ACCOUNTNUMBER>
    * my-stepfunction-ecs-app-dev-target-bucket-<YOUR_ACCOUNTNUMBER>
* Amazon ECR
    * my-stepfunction-ecs-app-repo - Make sure to check if the repository has the code/image
* Amazon SNS
    * my-stepfunction-ecs-app-SNSTopic - Note this is not subscribed to any endpoint. You may do so subscribing to your email Id, text message etc., using [AWS Console, API or CLI](https://docs.aws.amazon.com/sns/latest/dg/sns-create-subscribe-endpoint-to-topic.html).
* CloudWatch – Log Groups
    * my-stepfunction-ecs-app-cloudwatch-log-group
        * /aws/ecs/fargate-app/<guid_1>
        * /aws/ecs/fargate-app/<guid_2>


Let’s test our stack from AWS Console>Step Functions> 

* Click on “my-stepfunction-ecs-app-ECSTaskStateMachine”.

* Click on “Start Execution”. The state machine will trigger the ECS Fargate task and will complete as below
* To see the process:
    * ECS: 
        * Navigate to AWS Console > ECS > Select your cluster
        * click on “Tasks” sub tab, select the task. and see the status. While the task runs you may notice the status will be in PROVISIONING, PENDING, RUNNING, STOPPED states
    * S3
        * Navigate to the output S3 bucket - my-stepfunction-ecs-app-dev-target-bucket-<YOUR_ACCOUNTNUMBER> to see the output
        * Note there could be a delay for the files to be processed by Amazon Kinesis, Kinesis Firehose to S3


![Alt text](stepfunction.png?raw=true "AWS Step Functions")


### Troubleshooting

* Java errors: Make sure to have JDK, maven installed for the compilation of the application code.
* Check if local Docker is running. 
* VPC - Check VPC [quota/limits](https://docs.aws.amazon.com/vpc/latest/userguide/amazon-vpc-limits.html). Current limit is 5 per region
* ECR Deployment - CLI V2 is used at this point. Refer aws [cli v1](https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login.html) vs [cli 2](https://docs.aws.amazon.com/cli/latest/reference/ecr/get-login-password.html) for issues
* Issues with running the installation/shell script
    * Windows users - Shell scripts by default opens in a new window and closes once done. To see the execution you can paste the script contents in a windows CMD and shall execute sequentially
    * If you are deploying through the provided installation/cleanup scripts, make sure to have “chmod +x exec.sh” or “chmod +777 exec.sh” (Elevate the execution permission of the scripts)
    * Linux Users - Permission issues could arise if you are not running as root user. you may have to “sudo su“ . 
* If you are running the steps manually, refer the “exec.sh” script for any difference in the command execution

### Pricing

* VPC, NAT Gateway pricing - https://aws.amazon.com/vpc/pricing/
* ECS - https://aws.amazon.com/ecs/pricing/
* VPC Private link pricing - https://aws.amazon.com/privatelink/pricing/
* Amazon Kinesis Data Streams - https://aws.amazon.com/kinesis/data-streams/pricing/
* Amazon Kinesis Data Firehose - https://aws.amazon.com/kinesis/data-firehose/pricing/
* Amazon S3 - https://aws.amazon.com/s3/pricing/

### 4. Code Cleanup

Terraform destroy command will delete all the infrastructure that were planned and applied. Since the S3 will have both sample input and the processed files generated, make sure to delete the files before initiating the destroy command. 
This can be done either in AWS Console or using AWS CLI (commands provided). See both options below

Using the cleanup script provided

1. Cleanup.sh
    1. Make sure to provide <YOUR_ACCOUNT_NUMBER>
    2. chmod +x cleanup.sh
    3. ./cleanup.sh

```
Manual Cleanup - Only do if you didn't do the above step
```

1. Clean up resources from the AWS Console
    1. Open AWS Console, select S3
    2. Navigate to the bucket created as part of the stack
    3. Delete the S3 bucket manually
    4. Similarly navigate to “ECR”, select the create repository - my-stepfunction-ecs-app-repo you may have more than one image pushed to the repository depending on changes (if any) done to your java code
    5. Select all the images and delete the images pushed
2. Clean up resources using AWS CLI

`# CLI Commands to delete the S3`

* `$ aws s3 rb s3://my-stepfunction-ecs-app-dev-source-bucket-<your-account-number> --force`
* `$ aws s3 rb s3://my-stepfunction-ecs-app-dev-target-bucket-<your-account-number> --force`
* `$ aws ecr batch-delete-image --repository-name my-stepfunction-ecs-app-repo --image-ids imageTag=latest`
* `$ aws ecr batch-delete-image --repository-name my-stepfunction-ecs-app-repo --image-ids imageTag=untagged`
* cd templates
* `terraform destroy –-auto-approve`

## Conclusion

You were able to launch an application process involving Amazon ECS and AWS Fargate which integrated with various AWS services. The post walked through deploying an application code packaged with Java using maven. You may use any combination of applicable programming languages to build your application logic. The sample provided has a Java code that is packaged using Dockerfile into the Amazon ECR.

We encourage you to try this example and see for yourself how this overall application design works within AWS. Then, it will just be a matter of replacing your current application, package them as Docker containers and let the Amazon ECS manage the application efficiently.

If you have any questions/feedback about this blog please provide your comments below!

## References

* [Amazon ECS Faqs](https://aws.amazon.com/ecs/faqs/)
* [AWS Fargate Faqs](https://aws.amazon.com/fargate/faqs/)
* [Amazon Kinesis](https://aws.amazon.com/kinesis/)
* [Docker Containers](https://www.docker.com/resources/what-container)
* [Terraform: Beyond the basics with AWS](https://aws.amazon.com/blogs/apn/terraform-beyond-the-basics-with-aws/)
* [VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-endpoints.html)
