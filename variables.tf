#######################################
# Load Balancer
#######################################
variable "name_prefix" {
  description = "Name prefix to resources"
  type        = string
  default     = null
}

variable "lb_arn_exists" {
  description = "If this variable is defined with the LB ARN, then will be use the a load balancer existing and don't will be create a new load balancer else will be created a load balancer"
  type        = string
  default     = null
}

variable "internal" {
  description = "If true, the LB will be internal"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Load balancer type, will can be application, gateway or network"
  type        = string
  default     = "application"
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle, It's only valid for Load Balancers of type application"
  type        = number
  default     = 400
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled via the AWS API, this will prevent Terraform from deleting the load balancer"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled, this is a network load balancer feature"
  type        = bool
  default     = true
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancer"
  type        = bool
  default     = true
}

variable "security_groups" {
  description = "A list of security group IDs to assign to the LB, It's only valid for Load Balancers of type application"
  type        = list(string)
  default     = null
}

variable "subnets" {
  description = "Is required at least two subnets different Availability Zones. Is a list of subnet IDs to attach to the LB, these subnets cannot be updated for Load Balancers of type network. Changing this value for load balancers of type network will force a recreation of the resource. Note that subnets or subnet_mapping is required"
  type        = list(string)
  default     = null
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer, can be ipv4 or dualstack. Please note that internal LBs can only use ipv4 as the ip_address_type. You can only change to dualstack ip_address_type if the selected subnets are IPv6 enabled"
  type        = string
  default     = "ipv4"
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether invalid header fields are dropped in application load balancers"
  type        = bool
  default     = false
}

variable "preserve_host_header" {
  description = "Indicates whether Host header should be preserve and forward to targets without any change"
  type        = bool
  default     = false
}

variable "enable_waf_fail_open" {
  description = "Indicates whether to route requests to targets if lb fails to forward the request to AWS WAF"
  type        = bool
  default     = false
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync, can be monitor, defensive, strictest"
  type        = string
  default     = "defensive"
}

variable "customer_owned_ipv4_pool" {
  description = "The ID of the customer owned ipv4 pool to use for this load balancer"
  type        = string
  default     = null
}

variable "use_tags_default" {
  description = "If true will be use the tags default to hosted zone"
  type        = bool
  default     = true
}

variable "ou_name" {
  description = "Organization unit name"
  type        = string
  default     = "no"
}

variable "tags" {
  description = "Tags to load balancer resourcers"
  type        = map(any)
  default     = {}
}

variable "access_logs" {
  description = "Define one S3 bucket to keep access logs"
  type = object({
    bucket  = string
    prefix  = optional(string, null)
    enabled = optional(bool, true)
  })
  default = null
}

variable "subnets_mapping" {
  description = "Can be set in network load balancers attaching one or more subnets. Note that subnets or subnet_mapping is required"
  type = list(object({
    subnet_id            = string
    private_ipv4_address = optional(string, null)
    ipv6_address         = optional(string, null)
    allocation_id        = optional(string, null)
  }))
  default = null
}

variable "load_balancer_create_timeout" {
  description = "Timeout value when creating the ALB"
  type        = string
  default     = "10m"
}

variable "load_balancer_update_timeout" {
  description = "Timeout value when updating the ALB"
  type        = string
  default     = "10m"
}

variable "load_balancer_delete_timeout" {
  description = "Timeout value when deleting the ALB"
  type        = string
  default     = "10m"
}

#######################################
# Target Group
#######################################
variable "elb_ssl_policy_default_listener" {
  description = "ELB SSL policy to listeners, should be use when TLS is active"
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
}

variable "target_groups" {
  description = "Define the target groups configurations for load balancer, including listeners and attachments"
  type = list(object({
    target_type                        = string
    name                               = optional(string, null)
    vpc_id                             = optional(string, null)
    port                               = optional(number, 80)
    protocol                           = optional(string, "HTTP")
    load_balancing_algorithm_type      = optional(string, null)
    tags                               = optional(map(any), {})
    connection_termination             = optional(bool, null)
    deregistration_delay               = optional(number, null)
    slow_start                         = optional(number, null)
    proxy_protocol_v2                  = optional(bool, false)
    lambda_multi_value_headers_enabled = optional(bool, false)
    preserve_client_ip                 = optional(string, null)
    ip_address_type                    = optional(string, null)

    health_check = optional(object({
      path                = optional(string)
      port                = optional(number)
      healthy_threshold   = optional(number)
      unhealthy_threshold = optional(number)
      protocol            = optional(string)
      matcher             = optional(string)
      interval            = optional(number)
      timeout             = optional(number)
      enabled             = optional(bool)
    }), null)

    stickiness = optional(object({
      enabled         = optional(bool)
      type            = optional(string)
      cookie_name     = optional(string)
      cookie_duration = optional(string)
    }), null)

    listeners = optional(list(object({
      port            = optional(number, 80)
      protocol        = optional(string, "HTTP")
      tags            = optional(map(any), {})
      ssl_policy      = optional(string)
      certificate_arn = optional(string)
      alpn_policy     = optional(string)

      default_actions = optional(list(object({
        type             = string
        target_group_arn = optional(string)
        order            = optional(string)

        redirect = optional(object({
          path        = optional(string)
          host        = optional(string)
          port        = optional(string)
          protocol    = optional(string)
          query       = optional(string)
          status_code = optional(string)
        }))

        fixed_response = optional(object({
          content_type = string
          message_body = optional(string)
          status_code  = optional(string)
        }))
      })))
    })))

    targets_attachment = optional(list(object({
      target_id         = string
      port              = optional(number)
      availability_zone = optional(string)
    })))
  }))
  default = null
}
