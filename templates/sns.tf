## SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
##
### SPDX-License-Identifier: MIT-0

resource "aws_sns_topic" "stepfunction_ecs_sns" {
  name = "${var.app_prefix}-SNSTopic"
}