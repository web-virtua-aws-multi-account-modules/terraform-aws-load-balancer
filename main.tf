locals {
  tags_lb = {
    "Name"  = "${var.name_prefix}"
    "tf-lb" = "${var.name_prefix}"
    "tf-ou" = var.ou_name
  }

  tags_tg = {
    "Name"  = "${var.name_prefix}-tg"
    "tf-tg" = "${var.name_prefix}-tg"
    "tf-ou" = var.ou_name
  }

  tags_listener = {
    "Name"        = "${var.name_prefix}-listener"
    "tf-listener" = "${var.name_prefix}-listener"
    "tf-ou"       = var.ou_name
  }

  listeners_normalized = flatten([
    for i, target_group in var.target_groups != null ? var.target_groups : [] : [
      for listener in target_group.listeners != null ? target_group.listeners : [] : [
        {
          target_group_index = i
          default_actions    = listener.default_actions
          port               = listener.port
          protocol           = listener.protocol
          tags               = listener.tags
          ssl_policy         = listener.ssl_policy
          certificate_arn    = listener.certificate_arn
        }
      ]
    ]
  ])

  targets_attachment_normalized = flatten([
    for i, target_group in var.target_groups != null ? var.target_groups : [] : [
      for target in target_group.targets_attachment != null ? target_group.targets_attachment : [] : [
        {
          target_group_index = i
          target_id          = target.target_id
          port               = target.port
          availability_zone  = target.availability_zone
        }
      ]
    ]
  ])
}

resource "aws_lb" "create_lb" {
  count = var.lb_arn_exists == null ? 1 : 0

  name                             = var.name_prefix
  internal                         = var.internal
  load_balancer_type               = var.load_balancer_type
  idle_timeout                     = var.idle_timeout
  enable_deletion_protection       = var.enable_deletion_protection
  enable_cross_zone_load_balancing = var.enable_cross_zone_load_balancing
  enable_http2                     = var.enable_http2
  security_groups                  = var.security_groups
  subnets                          = var.subnets
  ip_address_type                  = var.ip_address_type
  drop_invalid_header_fields       = var.drop_invalid_header_fields
  preserve_host_header             = var.preserve_host_header
  enable_waf_fail_open             = var.enable_waf_fail_open
  desync_mitigation_mode           = var.desync_mitigation_mode
  customer_owned_ipv4_pool         = var.customer_owned_ipv4_pool
  tags                             = merge(var.tags, var.use_tags_default ? local.tags_lb : {})

  # If use a logs bucket is necessary gives the LB permissions
  dynamic "access_logs" {
    for_each = var.access_logs != null ? [1] : []

    content {
      bucket  = var.access_logs.bucket
      prefix  = var.access_logs.prefix
      enabled = var.access_logs.enabled
    }
  }

  dynamic "subnet_mapping" {
    for_each = var.subnets_mapping != null ? var.subnets_mapping : []

    content {
      subnet_id            = subnet_mapping.value.subnet_id
      private_ipv4_address = subnet_mapping.value.private_ipv4_address
      ipv6_address         = subnet_mapping.value.ipv6_address
      allocation_id        = subnet_mapping.value.allocation_id
    }
  }

  timeouts {
    create = var.load_balancer_create_timeout
    update = var.load_balancer_update_timeout
    delete = var.load_balancer_delete_timeout
  }
}

#######################################
# Target Group
#######################################
data "aws_lb" "alb_existing" {
  arn = var.lb_arn_exists
}

resource "aws_lb_target_group" "create_lb_target_group" {
  count = length(var.target_groups)

  name                               = var.target_groups[count.index].name != null ? var.target_groups[count.index].name : "${var.name_prefix}-tg-${count.index + 1}"
  vpc_id                             = var.target_groups[count.index].vpc_id != null ? var.target_groups[count.index].vpc_id : try(data.aws_lb.alb_existing.vpc_id, aws_lb.create_lb[0].vpc_id)
  port                               = var.target_groups[count.index].port
  protocol                           = var.target_groups[count.index].protocol
  target_type                        = var.target_groups[count.index].target_type
  load_balancing_algorithm_type      = var.target_groups[count.index].load_balancing_algorithm_type
  tags                               = merge(var.target_groups[count.index].tags, var.use_tags_default ? local.tags_tg : {})
  connection_termination             = var.target_groups[count.index].connection_termination
  deregistration_delay               = var.target_groups[count.index].deregistration_delay
  slow_start                         = var.target_groups[count.index].slow_start
  proxy_protocol_v2                  = var.target_groups[count.index].proxy_protocol_v2
  lambda_multi_value_headers_enabled = var.target_groups[count.index].lambda_multi_value_headers_enabled
  preserve_client_ip                 = var.target_groups[count.index].preserve_client_ip
  ip_address_type                    = var.target_groups[count.index].ip_address_type

  dynamic "health_check" {
    for_each = var.target_groups[count.index].health_check != null ? [1] : []

    content {
      path                = var.target_groups[count.index].health_check.path
      port                = var.target_groups[count.index].health_check.port
      healthy_threshold   = var.target_groups[count.index].health_check.healthy_threshold
      unhealthy_threshold = var.target_groups[count.index].health_check.unhealthy_threshold
      protocol            = var.target_groups[count.index].health_check.protocol
      matcher             = var.target_groups[count.index].health_check.matcher
      interval            = var.target_groups[count.index].health_check.interval
      timeout             = var.target_groups[count.index].health_check.timeout
      enabled             = var.target_groups[count.index].health_check.enabled
    }
  }

  dynamic "stickiness" {
    for_each = var.target_groups[count.index].stickiness != null ? [1] : []

    content {
      enabled = var.target_groups[count.index].stickiness.enabled
      type    = var.target_groups[count.index].stickiness.type
    }
  }

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [
    aws_lb.create_lb
  ]
}

#######################################
# Listeners
#######################################
resource "aws_lb_listener" "create_listener" {
  count = length(local.listeners_normalized)

  load_balancer_arn = var.lb_arn_exists != null ? var.lb_arn_exists : aws_lb.create_lb[0].arn
  port              = local.listeners_normalized[count.index].port
  protocol          = local.listeners_normalized[count.index].protocol
  tags              = merge(local.listeners_normalized[count.index].tags, var.use_tags_default ? local.tags_listener : {})
  ssl_policy        = try(local.listeners_normalized[count.index].certificate_arn, null) != null ? try(local.listeners_normalized[count.index].ssl_policy, var.elb_ssl_policy_default_listener) : null
  certificate_arn   = try(local.listeners_normalized[count.index].certificate_arn, null)
  alpn_policy       = try(local.listeners_normalized[count.index].alpn_policy, null)

  dynamic "default_action" {
    for_each = local.listeners_normalized[count.index].default_actions != null ? local.listeners_normalized[count.index].default_actions : []

    content {
      type             = default_action.value.type
      order            = default_action.value.order
      target_group_arn = aws_lb_target_group.create_lb_target_group[local.listeners_normalized[count.index].target_group_index].arn

      dynamic "redirect" {
        for_each = default_action.value.redirect != null ? [1] : []

        content {
          path        = default_action.value.redirect.path
          host        = default_action.value.redirect.host
          port        = default_action.value.redirect.port
          protocol    = default_action.value.redirect.protocol
          query       = default_action.value.redirect.query
          status_code = default_action.value.redirect.status_code
        }
      }

      dynamic "fixed_response" {
        for_each = default_action.value.fixed_response != null ? [1] : []

        content {
          content_type = default_action.value.fixed_response.content_type
          message_body = default_action.value.fixed_response.message_body
          status_code  = default_action.value.fixed_response.status_code
        }
      }
    }
  }

  lifecycle {
    create_before_destroy = false
  }

  depends_on = [
    aws_lb_target_group.create_lb_target_group
  ]
}

resource "aws_lb_target_group_attachment" "create_target_groups_attachment" {
  count = length(local.targets_attachment_normalized)

  target_id         = local.targets_attachment_normalized[count.index].target_id
  port              = try(local.targets_attachment_normalized[count.index].port, aws_lb_target_group.create_lb_target_group[local.targets_attachment_normalized[count.index].target_group_index].port)
  availability_zone = try(local.targets_attachment_normalized[count.index].availability_zone, null)
  target_group_arn  = aws_lb_target_group.create_lb_target_group[local.targets_attachment_normalized[count.index].target_group_index].arn

  depends_on = [
    aws_lb_target_group.create_lb_target_group
  ]
}
