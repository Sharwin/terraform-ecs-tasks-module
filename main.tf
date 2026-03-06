terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.35"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source = "./network"
}

resource "aws_ecs_cluster" "this" {
  name = "demo-ecs-cluster"
}

module "ecs_ui" {
  source = "./ecs-task-module"

  name              = "demo-angular-ui"
  cluster_arn       = aws_ecs_cluster.this.arn
  cpu               = 512
  memory            = 1024
  image             = "public.ecr.aws/docker/library/nginx:latest"
  container_port    = 80
  subnet_ids        = module.network.private_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]
  assign_public_ip  = false
  desired_count     = 1
  target_group_arn  = aws_lb_target_group.ui.arn
}

module "ecs_node" {
  source = "./ecs-task-module"

  name              = "demo-node21-api"
  cluster_arn       = aws_ecs_cluster.this.arn
  cpu               = 256
  memory            = 512
  image             = "public.ecr.aws/docker/library/node:21-alpine"
  container_port    = 3000
  subnet_ids        = module.network.private_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]
  assign_public_ip  = false
  desired_count     = 1
  target_group_arn  = aws_lb_target_group.node.arn
  command           = ["node", "-e", "require('http').createServer((_,res)=>res.end('Hello from Node 21')).listen(3000)"]
}

module "ecs_java" {
  source = "./ecs-task-module"

  name              = "demo-java21-service"
  cluster_arn       = aws_ecs_cluster.this.arn
  cpu               = 512
  memory            = 1024
  image             = "public.ecr.aws/docker/library/openjdk:21-jdk"
  container_port    = 8080
  subnet_ids        = module.network.private_subnet_ids
  security_group_ids = [module.network.ecs_sg_id]
  assign_public_ip  = false
  desired_count     = 1
  target_group_arn  = aws_lb_target_group.java.arn
  command           = ["bash", "-c", "echo 'Hello from Java 21' > index.html && python -m http.server 8080"]
}

resource "aws_lb" "this" {
  name               = "demo-ecs-alb"
  load_balancer_type = "application"
  security_groups    = [module.network.alb_sg_id]
  subnets            = module.network.public_subnet_ids
}

resource "aws_lb_target_group" "ui" {
  name        = "tg-ui"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id
}

resource "aws_lb_target_group" "node" {
  name        = "tg-node"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id
}

resource "aws_lb_target_group" "java" {
  name        = "tg-java"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.network.vpc_id
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }
}

resource "aws_lb_listener_rule" "ui" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ui.arn
  }

  condition {
    path_pattern {
      values = ["/ui*", "/"]
    }
  }
}

resource "aws_lb_listener_rule" "node" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node.arn
  }

  condition {
    path_pattern {
      values = ["/api*"]
    }
  }
}

resource "aws_lb_listener_rule" "java" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.java.arn
  }

  condition {
    path_pattern {
      values = ["/java*"]
    }
  }
}
