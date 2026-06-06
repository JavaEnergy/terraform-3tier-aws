variable "project_name" { type = string }
variable "environment" { type = string }
variable "region_label" { type = string }
variable "ecs_cluster_name" { type = string }
variable "ecs_service_name" { type = string }
variable "sns_topic_arn" { type = string }
variable "cpu_threshold" { type = number }
