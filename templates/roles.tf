## SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
##
### SPDX-License-Identifier: MIT-0

locals {
  iam_role_name       = "${var.app_prefix}-ECSRunTaskSyncExecutionRole"
  iam_policy_name     = "FargateTaskNotificationAccessPolicy"
  iam_task_role_policy_name = "${var.app_prefix}-ECS-Task-Role-Policy"
}

resource "aws_iam_role" "stepfunction_ecs_role" {
  name               = "${local.iam_role_name}"
  assume_role_policy = "${data.aws_iam_policy_document.stepfunction_ecs_policy_document.json}"
}
data "aws_iam_policy_document" "stepfunction_ecs_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy" "stepfunction_ecs_policy" {
  name = "${local.iam_policy_name}"
  role = "${aws_iam_role.stepfunction_ecs_role.id}"
  # Policy type: Inline policy
  # StepFunctionsGetEventsForECSTaskRule is AWS Managed Rule
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:GetRole",
                "iam:PassRole"
            ],
            "Resource": "*"
        },
        {
            "Sid": "AllowPushPull",
            "Resource": [
                "${aws_ecr_repository.stepfunction_ecs_ecr_repo.arn}"
            ],
            "Effect": "Allow",
            "Action": [
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload"
            ]
        },
        {
            "Action": [
                "sns:Publish"
            ],
            "Resource": [
                "${aws_sns_topic.stepfunction_ecs_sns.arn}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ecs:RunTask"
            ],
            "Resource": [
                "${aws_ecs_task_definition.stepfunction_ecs_task_definition.arn}"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "ecs:StopTask",
                "ecs:DescribeTasks"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "events:PutTargets",
                "events:PutRule",
                "events:DescribeRule"
            ],
            "Resource": [
                "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"
            ],
            "Effect": "Allow"
        },
         {
            "Effect": "Allow",
            "Action": [
                "kinesis:PutRecord"
            ],
            "Resource": [
                "${aws_kinesis_stream.stepfunction_ecs_kinesis_stream.arn}"
            ]
        }
    ]
}
EOF
}


###
# ECS Tasks - role and executution roles
###

resource "aws_iam_role" "stepfunction_ecs_task_execution_role" {
  name = "${var.app_prefix}-ECS-TaskExecution-Role"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
resource "aws_iam_role" "stepfunction_ecs_task_role" {
  name = "${var.app_prefix}-ECS-Task-Role"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
}
 
resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = "${aws_iam_role.stepfunction_ecs_task_execution_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Grant task role for the actions to be performed
resource "aws_iam_role_policy_attachment" "ecs_task_role_s3_attachment" {
  role       = "${aws_iam_role.stepfunction_ecs_task_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}


resource "aws_iam_role_policy" "ecs_task_role_s3_attachment_policy" {
  name = "${local.iam_task_role_policy_name}"
  role = "${aws_iam_role.stepfunction_ecs_task_role.id}"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
       {
            "Effect": "Allow",
            "Action": [
                "s3:put*",
                "s3:get*",
                "s3:list*"
            ],
            "Resource": "*"
        },
         {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetRecords",
                "kinesis:PutRecords"

            ],
            "Resource": [
                "${aws_kinesis_stream.stepfunction_ecs_kinesis_stream.arn}"
            ]
        }
    ]
}
EOF
}


resource "aws_iam_role" "ecs_firehose_delivery_role" {
  name = "${var.app_prefix}-firehose-delivery-Role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_delivery_role_kinesis_attachment" {
  role       = "${aws_iam_role.ecs_firehose_delivery_role.name}"
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisReadOnlyAccess"
}


resource "aws_iam_role_policy" "ecs_firehose_delivery_role_policy" {
  name = "${local.iam_policy_name}"
  role = "${aws_iam_role.ecs_firehose_delivery_role.id}"
  
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:GetLogEvents",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:put*",
                "s3:get*",
                "s3:list*"
            ],
            "Resource": "*"
        },
         {
            "Effect": "Allow",
            "Action": [
                "kinesis:DescribeStream",
                "kinesis:GetRecords"
            ],
            "Resource": [
                "${aws_kinesis_stream.stepfunction_ecs_kinesis_stream.arn}"
            ]
        }
    ]
}
EOF
}
