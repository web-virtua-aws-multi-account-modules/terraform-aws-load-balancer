# AWS Load Balancer for multiples accounts and regions with Terraform module
* This module simplifies creating and configuring of the Load Balancer across multiple accounts and regions on AWS

* Is possible use this module with one region using the standard profile or multi account and regions using multiple profiles setting in the modules.

## Actions necessary to use this module:

* Create file versions.tf with the exemple code below:
```hcl
terraform {
  required_version = ">= 1.1.3"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.9"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 2.0"
    }
  }
}
```

* Criate file provider.tf with the exemple code below:
```hcl
provider "aws" {
  alias   = "alias_profile_a"
  region  = "us-east-1"
  profile = "my-profile"
}

provider "aws" {
  alias   = "alias_profile_b"
  region  = "us-east-2"
  profile = "my-profile"
}
```


## Features enable of Load Balancer configurations for this module:

- Load balancer
- Target groups
- Listeners
- Target groups attachment

## Usage exemples
### OBS: This module is able to create a configuration with one load balancer existing or creating a new, if definet the lb_arn_exists variable with ARN, the configurations of the target groups, listeners and attachments will be over the load balance set else will be create a new load balancer and the configuration will be over it.

### Create load balancer application type using only HTTP and target to instance EC2

```hcl
module "loadbalancer_test_http" {
  source             = "web-virtua-aws-multi-account-modules/load-balancer/aws"
  name_prefix        = "tf-lb-test-http"
  load_balancer_type = "application"
  target_groups      = [
    {
      target_type = "instance"
      port     = 80
      protocol = "HTTP"
      health_check = {
        path = "/"
        port = 80
      }
      targets_attachment = [
        {
          target_id = "i-0618...85fb1f"
          ip        = 80
        }
      ]
      stickiness = {
        enabled = true
        type    = "lb_cookie"
      }
      listeners = [
        {
          port     = 80
          protocol = "HTTP"
          default_actions = [
            {
              type = "forward"
            }
          ]
        }
      ]
    },
  ]

  security_groups = [
    "sg-0a0bc4269...33267"
  ]

  subnets = [
    "subnet-05b87...a88e8"
  ]

  providers = {
    aws = aws.alias_profile_b
  }
}
```

### Create load balancer application type, target to instance EC2 and redirecting to HTTPS

```hcl
module "loadbalancer_test_https" {
  source             = "web-virtua-aws-multi-account-modules/load-balancer/aws"
  name_prefix        = "tf-lb-test-https"
  load_balancer_type = "application"
  target_groups      = [
    {
      target_type = "instance"
      port     = 80
      protocol = "HTTP"
      health_check = {
        path = "/"
        port = 80
      }
      targets_attachment = [
        {
          target_id = "i-0618...85fb1f"
          ip        = 80
        }
      ]
      stickiness = {
        enabled = true
        type    = "lb_cookie"
      }
      listeners = [
        {
          port     = 80
          protocol = "HTTP"
          default_actions = [
            {
              type             = "redirect"
              redirect = {
                port        = 443
                protocol    = "HTTPS"
                status_code = "HTTP_301"
              }
            }
          ]
        },
        {
          port     = 443
          protocol = "HTTPS"
          certificate_arn = "arn:aws:acm:us-east-1:380000006012:certificate/8f4fce01-5d8...137cc243"
          default_actions = [
            {
              type             = "forward"
            }
          ]
        },
      ]
    },
  ]

  security_groups = [
    "sg-0a0bc4269...33267"
  ]

  subnets = [
    "subnet-05b87...a88e8"
  ]

  providers = {
    aws = aws.alias_profile_b
  }
}
```

### Create load balancer network type

```hcl
module "loadbalancer_network_test" {
  source               = "web-virtua-aws-multi-account-modules/load-balancer/aws"
  name_prefix          = "tf-lb-test-network"
  load_balancer_type   = "network"

  subnets = [
    "subnet-05b87...a88e8"
  ]

  providers = {
    aws = aws.alias_profile_a
  }
}
```

### Create load balancer network type with subnet mappings

```hcl
module "loadbalancer_network_test_map" {
  source               = "web-virtua-aws-multi-account-modules/load-balancer/aws"
  name_prefix          = "tf-lb-test-mapping-network"
  load_balancer_type   = "network"

  subnets_mapping = [
    {
      subnet_id = "subnet-05b87...a88e8"
    },
    {
      subnet_id = "subnet-gffff7...aoiy"
    }
  ]

  providers = {
    aws = aws.alias_profile_b
  }
}
```

## Variables

| Name | Type | Default | Required | Description | Options |
|------|-------------|------|---------|:--------:|:--------|
| name_prefix | `string` | `null` | no | Name prefix to resources | `-` |
| lb_arn_exists | `string` | `null` | no | If this variable is defined with the LB ARN, then will be use the a load balancer existing and don't will be create a new load balancer else will be created a load balancer | `-` |
| internal | `bool` | `false` | no | If true, the LB will be internal | `*`false <br> `*`true |
| load_balancer_type | `string` | `application` | no | Load balancer type, will can be application, gateway or network | `-` |
| idle_timeout | `number` | `400` | no | The time in seconds that the connection is allowed to be idle, It's only valid for Load Balancers of type application | `-` |
| enable_deletion_protection | `bool` | `false` | no | If true, deletion of the load balancer will be disabled via the AWS API, this will prevent Terraform from deleting the load balancer | `*`false <br> `*`true |
| enable_cross_zone_load_balancing | `bool` | `true` | no | If true, cross-zone load balancing of the load balancer will be enabled, this is a network load balancer feature | `*`false <br> `*`true |
| enable_http2 | `bool` | `true` | no | Indicates whether HTTP/2 is enabled in application load balancer | `*`false <br> `*`true |
| security_groups | `list(string)` | `null` | no | A list of security group IDs to assign to the LB, It's only valid for Load Balancers of type application" | `-` |
| subnets | `list(string)` | `null` | no | Is required at least two subnets different Availability Zones. Is a list of subnet IDs to attach to the LB, these subnets cannot be updated for Load Balancers of type network. Changing this value for load balancers of type network will force a recreation of the resource. Note that subnets or subnet_mapping is required | `-` |
| ip_address_type | `string` | `ipv4` | no | The type of IP addresses used by the subnets for your load balancer, can be ipv4 or dualstack. Please note that internal LBs can only use ipv4 as the ip_address_type. You can only change to dualstack ip_address_type if the selected subnets are IPv6 enabled | `-` |
| drop_invalid_header_fields | `bool` | `false` | no | Indicates whether invalid header fields are dropped in application load balancers | `*`false <br> `*`true |
| preserve_host_header | `bool` | `false` | no | Indicates whether Host header should be preserve and forward to targets without any change | `*`false <br> `*`true |
| enable_waf_fail_open | `bool` | `false` | no | Indicates whether to route requests to targets if lb fails to forward the request to AWS WAF | `*`false <br> `*`true |
| desync_mitigation_mode | `string` | `defensive` | no | Determines how the load balancer handles requests that might pose a security risk to an application due to HTTP desync, can be monitor, defensive, strictest | `-` |
| customer_owned_ipv4_pool | `string` | `null` | no | The ID of the customer owned ipv4 pool to use for this load balancer | `-` |
| use_tags_default | `bool` | `true` | no | If true will be use the tags default to hosted zone | `*`false <br> `*`true |
| ou_name | `string` | `no` | no | Organization unit name | `-` |
| tags | `map(any)` | `{}` | no | Tags to load balancer resourcers | `-` |
| access_logs | `object` | `null` | no | Define one S3 bucket to keep access logs | `-` |
| subnets_mapping | `list(object)` | `null` | no | Can be set in network load balancers attaching one or more subnets. Note that subnets or subnet_mapping is required | `-` |
| load_balancer_create_timeout | `string` | `10m` | no | Timeout value when creating the ALB | `-` |
| load_balancer_update_timeout | `string` | `10m` | no | Timeout value when updating the ALB | `-` |
| load_balancer_delete_timeout | `string` | `10m` | no | Timeout value when deleting the ALB | `-` |
| elb_ssl_policy_default_listener | `string` | `ELBSecurityPolicy-2016-08` | no | ELB SSL policy to listeners, should be use when TLS is active | `-` |
| target_groups | `list(object)` | `null` | no | Define the target groups configurations for load balancer, including listeners and attachments | `-` |


* Model of variable access_logs
```hcl
variable "access_logs" {
  description = "Define one S3 bucket to keep access logs"
  type = object({
    bucket  = string
    prefix  = optional(string, null)
    enabled = optional(bool, true)
  })
  default = [
    bucket  = "bucket-logs"
    prefix  = "errors"
    enabled = true
  ]
}
```

* Model of variable subnets_mapping
```hcl
variable "subnets_mapping" {
  description = "Can be set in network load balancers attaching one or more subnets. Note that subnets or subnet_mapping is required"
  type = list(object({
    subnet_id            = string
    private_ipv4_address = optional(string, null)
    ipv6_address         = optional(string, null)
    allocation_id        = optional(string, null)
  }))
  default = [
    {
      subnet_id = "subnet-05b87...a88e8"
    }
  ]
}
```

* Model of variable target_groups, above a exemple of a list with complete configurations to target groups, listeners and attachments. It's a complex object to get can make many types of configurations possibles, the type is not required you write, this is above to see the possibilities
```hcl
variable "target_groups" {
  description = "Define the target groups configurations for load balancer"
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
  default = [
    {
      target_type = "instance"
      port     = 80
      protocol = "HTTP"
      health_check = {
        path = "/"
        port = 80
      }
      targets_attachment = [
        {
          target_id = "i-0618...85fb1f"
          ip        = 80
        }
      ]
      stickiness = {
        enabled = true
        type    = "lb_cookie"
      }
      listeners = [
        {
          port     = 80
          protocol = "HTTP"
          default_actions = [
            {
              type = "forward"
            }
          ]
        }
      ]
    },
  ]
}
```


## Resources

| Name | Type |
|------|------|
| [aws_lb.create_lb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_target_group.create_lb_target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_lb_listener.create_listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_target_group_attachment.create_target_groups_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group_attachment) | resource |

## Outputs

| Name | Description |
|------|-------------|
| `lb` | All load balancer |
| `lb_dns_name` | Load balancer DNS name |
| `lb_arn` | Load balancer ARN |
| `lb_zone_id` | Load balancer zone ID |
| `target_groups` | Target groups |
| `target_groups_ids` | Target group IDs |
| `target_groups_arns` | Target group ARNs |
| `listeners` | Listeners |
| `listeners_arns` | Listeners ARNs |
| `target_groups_attachment` | Target groups attachment |
