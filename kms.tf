data "aws_iam_policy_document" "kms_key" {
  count = var.kms_account_access_list == null ? 0 : 1
  statement {
    sid = "OwnerAccess"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.kms_account_access_list == null ? [] : [{}]
    content {
      actions   = ["kms:Decrypt"]
      resources = ["*"]
      principals {
        type        = "AWS"
        identifiers = local.identifiers
      }
    }
  }
}

resource "aws_kms_key" "db_credential_key" {
  count                   = var.kms_account_access_list == null ? 0 : 1
  description             = "KMS key used to encrypt the database credentials, and belongs to ${local.name}"
  deletion_window_in_days = var.db_kms_recovery_window_in_days
  policy                  = data.aws_iam_policy_document.kms_key[0].json
}

resource "aws_kms_alias" "db_credential_alias" {
  count         = var.kms_account_access_list == null ? 0 : 1
  name_prefix   = "alias/${local.name}-${var.kms_alias}"
  target_key_id = aws_kms_key.db_credential_key[0].arn
}
