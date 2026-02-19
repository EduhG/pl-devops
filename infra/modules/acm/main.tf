# ##################################################################
# Route53 and ACM for ALB
# ##################################################################
# resource "aws_acm_certificate" "cert" {
#   domain_name       = var.domain_name
#   validation_method = "DNS"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options :
#     dvo.domain_name => dvo
#   }

#   zone_id = var.zone_id
#   name    = each.value.resource_record_name
#   type    = each.value.resource_record_type
#   records = [each.value.resource_record_value]
#   ttl     = 60

#   depends_on = [aws_acm_certificate.cert]
# }

# resource "aws_acm_certificate_validation" "validation" {
#   certificate_arn         = aws_acm_certificate.cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
# }


resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# resource "aws_route53_record" "validation" {
#   for_each = {
#     for dvo in aws_acm_certificate.cert.domain_validation_options :
#     dvo.domain_name => dvo
#   }

#   name    = each.value.resource_record_name
#   type    = each.value.resource_record_type
#   zone_id = var.zone_id
#   records = [each.value.resource_record_value]
#   ttl     = 60
# }

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.zone_id

  depends_on = [aws_acm_certificate.cert]
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
