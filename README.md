## ECS Task Module Demo

This repository contains:

- A reusable Terraform module in `ecs-task-module` that creates an ECS Fargate task definition and service, optionally attached to an ALB target group.
- A root configuration that:
  - Creates networking (VPC, subnets, security groups).
  - Creates an ECS cluster.
  - Instantiates the module three times:
    - One ECS service simulating an Angular 21 UI (using an `nginx` image as a placeholder).
    - One ECS service running a Node 21 HTTP server.
    - One ECS service running a Java 21-based simple HTTP server.
  - Creates an ALB with path-based routing to each service.

### How to use

1. Ensure your AWS credentials are configured (e.g. via environment variables or AWS CLI).
2. From the repository root, run:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. After apply, Terraform will output the ALB DNS name (you can also find it in the AWS console). Test:
   - `http://<alb-dns>/` or `/ui` for the UI.
   - `http://<alb-dns>/api` for the Node 21 service.
   - `http://<alb-dns>/java` for the Java 21 service.
