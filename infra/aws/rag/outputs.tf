output "docs_bucket" { value = aws_s3_bucket.docs.bucket }
output "knowledge_base_id" { value = aws_bedrockagent_knowledge_base.docs.id }
output "knowledge_base_arn" { value = aws_bedrockagent_knowledge_base.docs.arn }
output "data_source_id" { value = aws_bedrockagent_data_source.docs.data_source_id }
output "guardrail_id" { value = aws_bedrock_guardrail.energy.guardrail_id }
output "guardrail_version" { value = aws_bedrock_guardrail_version.v1.version }
