 ## SPDX-FileCopyrightText: Copyright 2019 Amazon.com, Inc. or its affiliates
 ##
 ### SPDX-License-Identifier: MIT-0

resource "aws_cloudwatch_log_group" "stepfunction_ecs_container_cloudwatch_loggroup" {
  name = "${var.app_prefix}-cloudwatch-log-group"

  tags = {
    Name        = "${var.app_prefix}-cloudwatch-log-group"
    Environment = "${var.stage_name}"
  }
}

resource "aws_cloudwatch_log_stream" "stepfunction_ecs_container_cloudwatch_logstream" {
  name           = "${var.app_prefix}-cloudwatch-log-stream"
  log_group_name =  "${aws_cloudwatch_log_group.stepfunction_ecs_container_cloudwatch_loggroup.name}"
}