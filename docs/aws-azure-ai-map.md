# AWS and Azure equivalents for the AI platform

| Capability | AWS (this lab) | Azure |
| --- | --- | --- |
| Foundation models, serverless | Amazon Bedrock (Nova, third-party models), inference profiles for cross-region | Azure AI Foundry model catalog (Azure OpenAI and others), global/data-zone deployments |
| OpenAI-compatible endpoint | Bedrock Mantle / Chat Completions | Azure OpenAI / Foundry inference endpoint |
| Managed RAG | Bedrock Knowledge Bases | Azure AI Search (integrated vectorization) with Foundry "on your data" / agent knowledge |
| Vector storage | S3 Vectors, OpenSearch Serverless, Aurora pgvector | Azure AI Search vector index, Cosmos DB vector search, PostgreSQL pgvector |
| Embedding model | Titan Text Embeddings V2 | text-embedding-3 models |
| Guardrails | Bedrock Guardrails (content filters, denied topics, PII, prompt attack, grounding) | Azure AI Content Safety, Prompt Shields, groundedness detection |
| Agents runtime | Bedrock AgentCore / Bedrock Agents | Azure AI Foundry Agent Service |
| Workload identity | IRSA / EKS Pod Identity, OIDC federation to IAM roles | AKS Workload Identity with Entra ID federated credentials |
| Private access | VPC interface endpoints (PrivateLink) | Private Endpoints |
| Secrets | Secrets Manager | Key Vault |
| Model quotas | Service Quotas per model and region (tokens and requests per minute) | Deployment quotas (tokens per minute) per model and region |
