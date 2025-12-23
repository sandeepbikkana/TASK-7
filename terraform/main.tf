provider "aws" {
  region = var.aws_region
}

################################
# DATA: DEFAULT VPC + ONE SUBNET PER AZ
################################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "alb" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }

  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

################################
# CLOUDWATCH LOG GROUP
################################

resource "aws_cloudwatch_log_group" "sandeep_strapi" {
  name              = "/ecs/sandeep-strapi"
  retention_in_days = 14
}


################################
# ECS CLUSTER (FARGATE ENABLED)
################################

resource "aws_ecs_cluster" "sandeep_strapi" {
  name = "sandeep-strapi-cluster"

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
}


################################
# SECURITY GROUPS
################################

resource "aws_security_group" "sandeep_alb_sg" {
  name   = "sandeep-strapi-alb-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sandeep_ecs_sg" {
  name   = "sandeep-strapi-ecs-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.sandeep_alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sandeep_rds_sg" {
  name   = "sandeep-strapi-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sandeep_ecs_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

################################
# RDS POSTGRES (SUPPORTED VERSION)
################################

resource "aws_db_subnet_group" "sandeep_strapi" {
  name       = "sandeep-strapi-db-subnets"
  subnet_ids = data.aws_subnets.alb.ids
}

resource "aws_db_instance" "sandeep_strapi" {
  identifier        = "sandeep-strapi-postgres"
  engine            = "postgres"
  engine_version    = "15.15"
  instance_class    = "db.t3.micro"
  allocated_storage = 20

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.sandeep_strapi.name
  vpc_security_group_ids = [aws_security_group.sandeep_rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
}

################################
# APPLICATION LOAD BALANCER
################################

resource "aws_lb" "sandeep_strapi" {
  name               = "sandeep-strapi-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sandeep_alb_sg.id]
  subnets            = data.aws_subnets.alb.ids
}

resource "aws_lb_target_group" "sandeep_blue" {
  name        = "sandeep-strapi-blue"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path = "/"
  }
}

resource "aws_lb_target_group" "sandeep_green" {
  name        = "sandeep-strapi-green"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "sandeep_http" {
  load_balancer_arn = aws_lb.sandeep_strapi.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sandeep_blue.arn
  }
}

################################
# IAM ROLES
################################

resource "aws_iam_role" "sandeep_ecs_execution_role" {
  name = "sandeep-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sandeep_ecs_execution_policy" {
  role       = aws_iam_role.sandeep_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "sandeep_codedeploy_role" {
  name = "sandeep-codedeploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "codedeploy.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "sandeep_codedeploy_policy" {
  role       = aws_iam_role.sandeep_codedeploy_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployRoleForECS"
}

################################
# BASELINE ECS TASK DEFINITION
################################

resource "aws_ecs_task_definition" "sandeep_strapi" {
  family                   = "sandeep-strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.sandeep_ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "strapi"
      image     = "public.ecr.aws/docker/library/nginx:latest"
      essential = true
      portMappings = [{ containerPort = 1337 }]
    }
  ])

  lifecycle {
    ignore_changes = [container_definitions]
  }
}

################################
# ECS SERVICE (CODEDEPLOY)
################################

resource "aws_ecs_service" "sandeep_strapi" {
  name            = "sandeep-strapi-service"
  cluster         = aws_ecs_cluster.sandeep_strapi.id
  task_definition = aws_ecs_task_definition.sandeep_strapi.arn
  desired_count   = 1

  deployment_controller {
    type = "CODE_DEPLOY"
  }

  capacity_provider_strategy {
  capacity_provider = "FARGATE"
  weight            = 1
  }

  network_configuration {
    subnets         = data.aws_subnets.alb.ids
    security_groups = [aws_security_group.sandeep_ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sandeep_blue.arn
    container_name   = "strapi"
    container_port   = 1337
  }
}

################################
# CODEDEPLOY BLUE/GREEN
################################

resource "aws_codedeploy_app" "sandeep_strapi" {
  name             = "sandeep-strapi-codedeploy"
  compute_platform = "ECS"
}

resource "aws_codedeploy_deployment_group" "sandeep_strapi" {
  app_name              = aws_codedeploy_app.sandeep_strapi.name
  deployment_group_name = "sandeep-strapi-dg"
  service_role_arn      = aws_iam_role.sandeep_codedeploy_role.arn

  deployment_style {
    deployment_type   = "BLUE_GREEN"
    deployment_option = "WITH_TRAFFIC_CONTROL"
  }

  deployment_config_name = "CodeDeployDefault.ECSCanary10Percent5Minutes"

  blue_green_deployment_config {
    deployment_ready_option {
      action_on_timeout = "CONTINUE_DEPLOYMENT"
    }

    terminate_blue_instances_on_deployment_success {
      action                           = "TERMINATE"
      termination_wait_time_in_minutes = 5
    }
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  ecs_service {
    cluster_name = aws_ecs_cluster.sandeep_strapi.name
    service_name = aws_ecs_service.sandeep_strapi.name
  }

  load_balancer_info {
    target_group_pair_info {
      prod_traffic_route {
        listener_arns = [aws_lb_listener.sandeep_http.arn]
      }

      target_group { name = aws_lb_target_group.sandeep_blue.name }
      target_group { name = aws_lb_target_group.sandeep_green.name }
    }
  }
}

################################
# CLOUDWATCH ALARMS
################################

resource "aws_cloudwatch_metric_alarm" "sandeep_high_cpu" {
  alarm_name          = "sandeep-strapi-high-cpu"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = aws_ecs_cluster.sandeep_strapi.name
    ServiceName = aws_ecs_service.sandeep_strapi.name
  }
}

resource "aws_cloudwatch_metric_alarm" "sandeep_high_memory" {
  alarm_name          = "sandeep-strapi-high-memory"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = aws_ecs_cluster.sandeep_strapi.name
    ServiceName = aws_ecs_service.sandeep_strapi.name
  }
}

################################
# CLOUDWATCH DASHBOARD
################################

resource "aws_cloudwatch_dashboard" "sandeep_strapi" {
  dashboard_name = "sandeep-strapi-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        width = 12
        height = 6
        properties = {
          title = "ECS CPU & Memory"
          region = var.aws_region
          metrics = [
            ["AWS/ECS","CPUUtilization","ClusterName",aws_ecs_cluster.sandeep_strapi.name,"ServiceName",aws_ecs_service.sandeep_strapi.name],
            ["AWS/ECS","MemoryUtilization","ClusterName",aws_ecs_cluster.sandeep_strapi.name,"ServiceName",aws_ecs_service.sandeep_strapi.name]
          ]
        }
      }
    ]
  })
}
