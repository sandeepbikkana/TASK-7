provider "aws" {
  region = var.aws_region
}

############################
# DEFAULT VPC & SUBNETS
############################

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

############################
# CLOUDWATCH LOG GROUP
############################

resource "aws_cloudwatch_log_group" "sandeep_strapi" {
  name              = "/ecs/sandeep-strapi"
  retention_in_days = 14
}

############################
# ECS CLUSTER (SPOT ENABLED)
resource "aws_ecs_cluster" "sandeep_strapi" {
  name = "sandeep-strapi-cluster"
}

resource "aws_ecs_cluster_capacity_providers" "sandeep_strapi" {
  cluster_name = aws_ecs_cluster.sandeep_strapi.name

  capacity_providers = [
    "FARGATE",
    "FARGATE_SPOT"
  ]

  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }
}

############################
# SECURITY GROUPS
############################

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

############################
# RDS POSTGRES
############################

resource "aws_db_subnet_group" "sandeep_strapi" {
  name       = "sandeep-strapi-db-subnet-group"
  subnet_ids = data.aws_subnets.alb.ids
}

resource "aws_db_instance" "sandeep_strapi" {
  identifier             = "sandeep-strapi-postgres"
  engine                 = "postgres"
  engine_version         = "15.15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.sandeep_strapi.name
  vpc_security_group_ids = [aws_security_group.sandeep_rds_sg.id]

  publicly_accessible = false
  skip_final_snapshot = true
}

############################
# APPLICATION LOAD BALANCER
############################

resource "aws_lb" "sandeep_strapi" {
  name               = "sandeep-strapi-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sandeep_alb_sg.id]
  subnets            = data.aws_subnets.alb.ids
}

resource "aws_lb_target_group" "sandeep_strapi" {
  name        = "sandeep-strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/admin"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "sandeep_http" {
  load_balancer_arn = aws_lb.sandeep_strapi.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sandeep_strapi.arn
  }
}

############################
# IAM ROLE (ECS EXECUTION)
############################

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

resource "aws_iam_role_policy_attachment" "sandeep_ecs_policy" {
  role       = aws_iam_role.sandeep_ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################
# ECS TASK DEFINITION
############################

resource "aws_ecs_task_definition" "sandeep_strapi" {
  family                   = "sandeep-strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.sandeep_ecs_execution_role.arn

  container_definitions = jsonencode([
    {
      name  = "strapi"
      image = "${var.ecr_repo}:${var.image_tag}"

      portMappings = [
        { containerPort = 1337 }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "APP_KEYS", value = var.app_keys },
        { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
        { name = "JWT_SECRET", value = var.jwt_secret },
        { name = "API_TOKEN_SALT", value = var.api_token_salt },
        { name = "DATABASE_CLIENT", value = "postgres" },
        { name = "DATABASE_HOST", value = aws_db_instance.sandeep_strapi.address },
        { name = "DATABASE_PORT", value = "5432" },
        { name = "DATABASE_NAME", value = var.db_name },
        { name = "DATABASE_USERNAME", value = var.db_username },
        { name = "DATABASE_PASSWORD", value = var.db_password }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.sandeep_strapi.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

############################
# ECS SERVICE (FARGATE SPOT)
############################

resource "aws_ecs_service" "sandeep_strapi" {
  name            = "sandeep-strapi-service"
  cluster         = aws_ecs_cluster.sandeep_strapi.id
  task_definition = aws_ecs_task_definition.sandeep_strapi.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 2
  }

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }

  network_configuration {
    subnets          = data.aws_subnets.alb.ids
    security_groups  = [aws_security_group.sandeep_ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.sandeep_strapi.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.sandeep_http]
}

# aws_cloudwatch_dashboard
resource "aws_cloudwatch_dashboard" "sandeep_strapi" {
  dashboard_name = "sandeep-strapi-ecs-dashboard"

  dashboard_body = jsonencode({
    widgets = [

      # CPU & Memory
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ECS CPU & Memory Utilization"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              aws_ecs_cluster.sandeep_strapi.name,
              "ServiceName",
              aws_ecs_service.sandeep_strapi.name
            ],
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName",
              aws_ecs_cluster.sandeep_strapi.name,
              "ServiceName",
              aws_ecs_service.sandeep_strapi.name
            ]
          ]
        }
      },

      # Running Task Count
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Running Task Count"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            [
              "AWS/ECS",
              "RunningTaskCount",
              "ClusterName",
              aws_ecs_cluster.sandeep_strapi.name,
              "ServiceName",
              aws_ecs_service.sandeep_strapi.name
            ]
          ]
        }
      },

      # Network In / Out
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "Network In / Out"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          metrics = [
            [
              "AWS/ECS",
              "NetworkRxBytes",
              "ClusterName",
              aws_ecs_cluster.sandeep_strapi.name,
              "ServiceName",
              aws_ecs_service.sandeep_strapi.name
            ],
            [
              "AWS/ECS",
              "NetworkTxBytes",
              "ClusterName",
              aws_ecs_cluster.sandeep_strapi.name,
              "ServiceName",
              aws_ecs_service.sandeep_strapi.name
            ]
          ]
        }
      },

      # ALB Unhealthy Targets (Critical for Spot)
      {
        type   = "metric"
        width  = 12
        height = 6
        properties = {
          title  = "ALB Unhealthy Targets"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            [
              "AWS/ApplicationELB",
              "UnHealthyHostCount",
              "LoadBalancer",
              aws_lb.sandeep_strapi.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.sandeep_strapi.arn_suffix
            ]
          ]
        }
      }
    ]
  })
}
