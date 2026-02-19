# # ##################################################################
# # S3 Bucket for ALB Access Logs
# # ##################################################################
# resource "aws_s3_bucket" "alb_logs" {
#   bucket = "${var.project_name}-alb-logs"

#   force_destroy = true
# }

# resource "aws_s3_bucket_versioning" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
#   bucket = aws_s3_bucket.alb_logs.id

#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# data "aws_caller_identity" "current" {}

# resource "aws_s3_bucket_policy" "allow_alb_logging" {
#   bucket = aws_s3_bucket.alb_logs.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow"
#         Principal = {
#           Service = "logdelivery.elasticloadbalancing.amazonaws.com"
#         }
#         Action   = "s3:PutObject"
#         Resource = "${aws_s3_bucket.alb_logs.arn}/alb/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
#       }
#     ]
#   })
# }


# ##################################################################
# ALB Security Group
# ##################################################################
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB security group"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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

# ##################################################################
# ALB
# ##################################################################
resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = var.load_balancer_type
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  # access_logs {
  #   bucket  = aws_s3_bucket.alb_logs.id
  #   prefix  = "alb"
  #   enabled = true
  # }

  tags = {
    Name = "${var.project_name}-alb"
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.project_name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Service unavailable"
      status_code  = "503"
    }
  }
}
