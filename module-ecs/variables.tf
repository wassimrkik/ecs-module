variable "project_name" {
  type = string
}
variable "task_cpu" {
  type = number
}
variable "task_mem" {
  type = number
}
variable "desired_count" {
  type = number
}
variable "task_port" {
  type = number
}
variable "task_role" {
  type = string
}
variable "execution_role" {
  type = string
}
variable "autoscaling_role" {
  type = string
}
variable "container_definitions" {
}
