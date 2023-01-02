output "lb" {
  description = "Load balancer"
  value       = try(aws_lb.create_lb[0], null)
}

output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = try(aws_lb.create_lb[0].dns_name, null)
}

output "lb_arn" {
  description = "Load balancer ARN"
  value       = try(aws_lb.create_lb[0].arn, null)
}

output "lb_zone_id" {
  description = "Load balancer zone ID"
  value       = try(aws_lb.create_lb[0].zone_id, null)
}

output "target_groups" {
  description = "Target groups"
  value       = try(aws_lb_target_group.create_lb_target_group, null)
}

output "target_groups_ids" {
  description = "Target group IDs"
  value       = try(aws_lb_target_group.create_lb_target_group[*].id, null)
}

output "target_groups_arns" {
  description = "Target group ARNs"
  value       = try(aws_lb_target_group.create_lb_target_group[*].arn, null)
}

output "listeners" {
  description = "Listeners"
  value       = try(aws_lb_listener.create_listener, null)
}

output "listeners_arns" {
  description = "Listeners ARNs"
  value       = try(aws_lb_listener.create_listener[*].arn, null)
}

output "target_groups_attachment" {
  description = "Target groups attachment"
  value       = try(aws_lb_target_group_attachment.create_target_groups_attachment, null)
}
