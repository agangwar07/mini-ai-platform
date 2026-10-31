locals {
  embedding_model_arn = "arn:aws:bedrock:${var.region}::foundation-model/amazon.titan-embed-text-v2:0"
}

# ---------- Documents ----------
resource "aws_s3_bucket" "docs" {
  bucket        = "${var.name}-${var.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "docs" {
  bucket                  = aws_s3_bucket.docs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ---------- Vector store (S3 Vectors) ----------
resource "aws_s3vectors_vector_bucket" "vectors" {
  vector_bucket_name = "${var.name}-vectors-${var.account_id}"
}

resource "aws_s3vectors_index" "docs" {
  vector_bucket_name = aws_s3vectors_vector_bucket.vectors.vector_bucket_name
  index_name         = "energy-docs"
  data_type          = "float32"
  dimension          = 1024
  distance_metric    = "cosine"

  metadata_configuration {
    non_filterable_metadata_keys = ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"]
  }
}

# ---------- Knowledge Base service role ----------
data "aws_iam_policy_document" "kb_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["bedrock.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [var.account_id]
    }
  }
}

resource "aws_iam_role" "kb" {
  name               = "${var.name}-kb-role"
  assume_role_policy = data.aws_iam_policy_document.kb_trust.json
}

data "aws_iam_policy_document" "kb_permissions" {
  statement {
    sid       = "ReadDocuments"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [aws_s3_bucket.docs.arn, "${aws_s3_bucket.docs.arn}/*"]
  }
  statement {
    sid       = "Embed"
    actions   = ["bedrock:InvokeModel"]
    resources = [local.embedding_model_arn]
  }
  statement {
    sid = "VectorIndex"
    actions = ["s3vectors:PutVectors", "s3vectors:GetVectors", "s3vectors:DeleteVectors",
    "s3vectors:QueryVectors", "s3vectors:GetIndex"]
    resources = [aws_s3vectors_index.docs.index_arn]
  }
}

resource "aws_iam_role_policy" "kb" {
  name   = "kb-permissions"
  role   = aws_iam_role.kb.id
  policy = data.aws_iam_policy_document.kb_permissions.json
}

# ---------- Knowledge Base and data source ----------
resource "aws_bedrockagent_knowledge_base" "docs" {
  name     = var.name
  role_arn = aws_iam_role.kb.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = local.embedding_model_arn
      embedding_model_configuration {
        bedrock_embedding_model_configuration {
          dimensions          = 1024
          embedding_data_type = "FLOAT32"
        }
      }
    }
  }

  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.docs.index_arn
    }
  }

  depends_on = [aws_iam_role_policy.kb]
}

resource "aws_bedrockagent_data_source" "docs" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.docs.id
  name              = "energy-docs-s3"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = aws_s3_bucket.docs.arn
    }
  }

  vector_ingestion_configuration {
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}

# ---------- Guardrail ----------
resource "aws_bedrock_guardrail" "energy" {
  name                      = "${var.name}-guardrail"
  description               = "PII masking, OT-control and competitor-pricing topics, prompt-attack filter"
  blocked_input_messaging   = "This request was blocked by the platform's AI usage policy."
  blocked_outputs_messaging = "The response was blocked by the platform's AI usage policy."

  content_policy_config {
    filters_config {
      type            = "PROMPT_ATTACK"
      input_strength  = "HIGH"
      output_strength = "NONE"
    }
    filters_config {
      type            = "MISCONDUCT"
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PASSWORD"
      action = "BLOCK"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "ot-control-changes"
      type       = "DENY"
      definition = "Requests to change protection relay settings, bypass safety interlocks, or issue control commands to operational technology such as turbines, substations or SCADA systems."
      examples = ["How do I bypass the overspeed trip on turbine T-17?",
      "Give me the commands to open breaker 52A remotely."]
    }
    topics_config {
      name       = "competitor-pricing"
      type       = "DENY"
      definition = "Questions about competitors' prices, discounts or commercial offers."
      examples   = ["What discount does our competitor give on gas turbine service contracts?"]
    }
  }
}

resource "aws_bedrock_guardrail_version" "v1" {
  guardrail_arn = aws_bedrock_guardrail.energy.guardrail_arn
  description   = "Lab 4 initial version"
}

# ---------- Let the gateway (Lab 3 role) use them ----------
data "aws_iam_policy_document" "gateway_rag" {
  statement {
    sid       = "RetrieveFromKnowledgeBase"
    actions   = ["bedrock:Retrieve"]
    resources = [aws_bedrockagent_knowledge_base.docs.arn]
  }
  statement {
    sid       = "ApplyGuardrail"
    actions   = ["bedrock:ApplyGuardrail"]
    resources = [aws_bedrock_guardrail.energy.guardrail_arn]
  }
}

resource "aws_iam_role_policy" "gateway_rag" {
  name   = "rag-retrieve-and-guardrail"
  role   = var.gateway_role_name
  policy = data.aws_iam_policy_document.gateway_rag.json
}
