locals {
  container_name = var.name

  environment_kv = [
    for k, v in var.environment : {
      name  = k
      value = v
    }
  ]
}

data "aws_region" "current" {}

resource "aws_iam_role" "task_execution" {
  count = var.task_execution_role_arn == "" ? 1 : 0

  name               = "${var.name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

data "aws_iam_policy_document" "task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  count      = var.task_execution_role_arn == "" ? 1 : 0
  role       = aws_iam_role.task_execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  count = var.task_role_arn == "" ? 1 : 0

  name               = "${var.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory

  execution_role_arn = var.task_execution_role_arn != "" ? var.task_execution_role_arn : aws_iam_role.task_execution[0].arn
  task_role_arn      = var.task_role_arn != "" ? var.task_role_arn : aws_iam_role.task[0].arn

  container_definitions = jsonencode([
    {
      name      = local.container_name
      image     = var.image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = local.environment_kv
      command     = length(var.command) > 0 ? var.command : null
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-region        = data.aws_region.current.name
          awslogs-group         = "/ecs/${var.name}"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 7
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = var.subnet_ids
    security_groups = var.security_group_ids
    assign_public_ip = var.assign_public_ip ? "ENABLED" : "DISABLED"
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != "" ? [1] : []

    content {
      target_group_arn = var.target_group_arn
      container_name   = local.container_name
      container_port   = var.container_port
    }
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
