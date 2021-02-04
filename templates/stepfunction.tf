## SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
##
### SPDX-License-Identifier: MIT-0

##################################################
# AWS Step Functions - Start Fargate Task On success notify SNS
##################################################
resource "aws_sfn_state_machine" "stepfunction_ecs_state_machine" {
  name     = "${var.app_prefix}-ECSTaskStateMachine"
  role_arn = "${aws_iam_role.stepfunction_ecs_role.arn}"

  definition = <<DEFINITION
{
  "Comment": "Application Process using AWS Step Functions and Amazon ECS & AWS Fargate",
  "StartAt": "Run Fargate Task",
  "TimeoutSeconds": 3600,
  "States": {
    "Run Fargate Task": {
      "Type": "Task",
      "Resource": "arn:aws:states:::ecs:runTask.sync",
      "Parameters": {
        "LaunchType": "FARGATE",
        "Cluster": "${aws_ecs_cluster.stepfunction_ecs_cluster.arn}",
        "TaskDefinition": "${aws_ecs_task_definition.stepfunction_ecs_task_definition.arn}",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": [
              "${aws_subnet.stepfunction_ecs_private_subnet1.id}"
            ],
            "AssignPublicIp": "ENABLED"
          }
        }
      },
      "Next": "Notify Success",
      "Catch": [
          {
            "ErrorEquals": [ "States.ALL" ],
            "Next": "Notify Failure"
          }
      ]
    },
    "Notify Success": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "AWS Fargate Task started by Step Functions succeeded",
        "TopicArn": "${aws_sns_topic.stepfunction_ecs_sns.arn}"
      },
      "End": true
    },
    "Notify Failure": {
      "Type": "Task",
      "Resource": "arn:aws:states:::sns:publish",
      "Parameters": {
        "Message": "AWS Fargate Task started by Step Functions failed",
        "TopicArn": "${aws_sns_topic.stepfunction_ecs_sns.arn}"
      },
      "End": true
    }
  }
}
DEFINITION
}

