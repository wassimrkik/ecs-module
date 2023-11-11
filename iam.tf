data "aws_caller_identity" "current" {
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

resource "aws_iam_role" "app" {
  name                 = "App_${var.role_name}"
  assume_role_policy   = data.aws_iam_policy_document.assume_role.json
  permissions_boundary = "arn:aws:iam::${local.aws_account_id}:policy/CE_AppAdminBoundary"
}

resource "aws_iam_policy" "app" {
  name        = "App_${var.role_name}"
  description = "App_${var.role_name}"
  policy      = var.policy_json
}

resource "aws_iam_role_policy_attachment" "custom_policy" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app.arn
}

resource "aws_iam_role_policy_attachment" "standard_policy" {
  count      = var.service == "ec2" ? 1 : 0
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::${local.aws_account_id}:policy/ce-SanofiSSM-PolicyforEC2"
}

resource "aws_iam_instance_profile" "app" {
  count = var.service == "ec2" ? 1 : 0
  name  = "App_${var.role_name}"
  role  = aws_iam_role.app.name
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["${var.service}.amazonaws.com"]
    }
  }
}
