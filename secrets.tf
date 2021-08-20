data "aws_iam_policy_document" "secret_access_policy" {
  # Allows secretsmanager to mange the secret.
  statement {
    actions = ["secretsmanager:*"]

    principals {
      type        = "Service"
      identifiers = ["secretsmanager.amazonaws.com"]
    }
    resources = ["*"]
  }

  # Allows other accounts to get the secret value.
  dynamic "statement" {
    for_each = var.kms_account_access_list == null ? [] : [{}]
    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = local.identifiers
      }
      condition {
        test     = "ForAnyValue:StringEquals"
        variable = "secretsmanager:VersionStage"
        values   = ["AWSCURRENT"]
      }
    }
  }
}

resource "aws_secretsmanager_secret" "secret" {
  name        = var.secret_id
  description = var.secret_description

  kms_key_id = var.kms_account_access_list == null ? "" : aws_kms_key.db_credential_key[0].key_id

  recovery_window_in_days = var.db_secret_recovery_window_in_days

  policy = data.aws_iam_policy_document.secret_access_policy.json

  tags = local.tags
  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}
