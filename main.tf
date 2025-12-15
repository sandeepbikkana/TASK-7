# provider "aws" {
#   region = var.aws_region
# }

# # -----------------------------
# # Default VPC & Subnets
# # -----------------------------
# data "aws_vpc" "default" {
#   default = true
# }

# data "aws_subnets" "default" {
#   filter {
#     name   = "vpc-id"
#     values = [data.aws_vpc.default.id]
#   }
# }

# # -----------------------------
# # ECS Cluster
# # -----------------------------
# resource "aws_ecs_cluster" "strapi" {
#   name = "strapi-cluster"
# }

# # -----------------------------
# # Security Groups
# # -----------------------------
# resource "aws_security_group" "alb_sg" {
#   name   = "strapi-alb-sg"
#   vpc_id = data.aws_vpc.default.id

#   ingress {
#     from_port   = 80
#     to_port     = 80
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "ecs_sg" {
#   name   = "strapi-ecs-sg"
#   vpc_id = data.aws_vpc.default.id

#   ingress {
#     from_port       = 1337
#     to_port         = 1337
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # -----------------------------
# # ALB
# # -----------------------------
# resource "aws_lb" "strapi" {
#   name               = "strapi-alb"
#   internal           = false
#   load_balancer_type = "application"
#   security_groups    = [aws_security_group.alb_sg.id]
#   subnets            = data.aws_subnets.default.ids
# }

# resource "aws_lb_target_group" "strapi" {
#   name        = "strapi-tg"
#   port        = 1337
#   protocol    = "HTTP"
#   vpc_id      = data.aws_vpc.default.id
#   target_type = "ip"

#   health_check {
#     path = "/"
#   }
# }

# resource "aws_lb_listener" "http" {
#   load_balancer_arn = aws_lb.strapi.arn
#   port              = 80
#   protocol          = "HTTP"

#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.strapi.arn
#   }
# }

# # -----------------------------
# # CloudWatch Logs
# # -----------------------------
# resource "aws_cloudwatch_log_group" "strapi" {
#   name              = "/ecs/strapi"
#   retention_in_days = 7
# }

# # -----------------------------
# # ECS Task Definition (FIXED)
# # -----------------------------
# resource "aws_ecs_task_definition" "strapi" {
#   family                   = "strapi-task"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   cpu                      = "512"
#   memory                   = "1024"

#   execution_role_arn = var.ecs_execution_role_arn

#   container_definitions = jsonencode([
#     {
#       name      = "strapi"
#       image     = "${var.ecr_repo}:${var.image_tag}"
#       essential = true

#       portMappings = [
#         {
#           containerPort = 1337
#           protocol      = "tcp"
#         }
#       ]

#       environment = [
#         { name = "APP_KEYS", value = var.app_keys },
#         { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
#         { name = "API_TOKEN_SALT", value = var.api_token_salt },
#         { name = "JWT_SECRET", value = var.jwt_secret }
#       ]

#       logConfiguration = {
#         logDriver = "awslogs"
#         options = {
#           awslogs-group         = aws_cloudwatch_log_group.strapi.name
#           awslogs-region        = var.aws_region
#           awslogs-stream-prefix = "ecs"
#         }
#       }
#     }
#   ])
# }

# # -----------------------------
# # ECS Service
# # -----------------------------
# resource "aws_ecs_service" "strapi" {
#   name            = "strapi-service"
#   cluster         = aws_ecs_cluster.strapi.id
#   task_definition = aws_ecs_task_definition.strapi.arn
#   desired_count   = 1
#   launch_type     = "FARGATE"

#   network_configuration {
#     subnets          = data.aws_subnets.default.ids
#     security_groups  = [aws_security_group.ecs_sg.id]
#     assign_public_ip = true
#   }

#   load_balancer {
#     target_group_arn = aws_lb_target_group.strapi.arn
#     container_name   = "strapi"
#     container_port   = 1337
#   }

#   depends_on = [aws_lb_listener.http]
# }








provider "aws" {
  region = var.aws_region
}

############################
# DEFAULT VPC & SUBNETS
############################

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

############################
# ECS CLUSTER
############################

resource "aws_ecs_cluster" "strapi" {
  name = "strapi-cluster"
}

############################
# SECURITY GROUPS
############################

resource "aws_security_group" "alb_sg" {
  name   = "strapi-alb-sg"
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

resource "aws_security_group" "ecs_sg" {
  name   = "strapi-ecs-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 1337
    to_port         = 1337
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "rds_sg" {
  name   = "strapi-rds-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_sg.id]
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

resource "aws_db_subnet_group" "strapi" {
  name       = "strapi-db-subnet-group"
  subnet_ids = data.aws_subnets.default.ids
}

resource "aws_db_instance" "strapi" {
  identifier             = "strapi-postgres"
  engine                 = "postgres"
  engine_version         = "15.15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20

  db_name                = var.db_name
  username               = var.db_username
  password               = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.strapi.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  publicly_accessible    = false
  skip_final_snapshot    = true
}

############################
# ALB
############################

resource "aws_lb" "strapi" {
  name               = "strapi-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.default.ids
}

resource "aws_lb_target_group" "strapi" {
  name        = "strapi-tg"
  port        = 1337
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.strapi.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.strapi.arn
  }
}

############################
# IAM ROLE (ECS EXECUTION)
############################

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsTaskExecutionRole-strapi"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

############################
# ECS TASK DEFINITION
############################

resource "aws_ecs_task_definition" "strapi" {
  family                   = "strapi-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name      = "strapi"
    image     = "${var.ecr_repo}:${var.image_tag}"
    essential = true

    portMappings = [{
      containerPort = 1337
    }]

    environment = [
      { name = "NODE_ENV", value = "production" },

      { name = "DATABASE_CLIENT",   value = "postgres" },
      { name = "DATABASE_HOST",     value = aws_db_instance.strapi.address },
      { name = "DATABASE_PORT",     value = "5432" },
      { name = "DATABASE_NAME",     value = var.db_name },
      { name = "DATABASE_USERNAME", value = var.db_username },
      { name = "DATABASE_PASSWORD", value = var.db_password },

      { name = "APP_KEYS",         value = var.app_keys },
      { name = "ADMIN_JWT_SECRET", value = var.admin_jwt_secret },
      { name = "JWT_SECRET",       value = var.jwt_secret },
      { name = "API_TOKEN_SALT",   value = var.api_token_salt }
    ]
  }])
}

############################
# ECS SERVICE
############################

resource "aws_ecs_service" "strapi" {
  name            = "strapi-service"
  cluster         = aws_ecs_cluster.strapi.id
  task_definition = aws_ecs_task_definition.strapi.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default.ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.strapi.arn
    container_name   = "strapi"
    container_port   = 1337
  }

  depends_on = [aws_lb_listener.http]
}
