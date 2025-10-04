---
title: Configuration
sidebar_position: 50
---

# Configuration

Applications need configuration data to run properly - from simple settings like API endpoints to sensitive information like database passwords. Kubernetes provides two main resources for managing configuration data:

**ConfigMaps** store non-confidential configuration data in key-value pairs, while **Secrets** handle sensitive information like passwords, tokens, and certificates with additional security measures.

## Configuration Management Benefits

- **Separation of concerns:** Keep configuration separate from application code
- **Environment flexibility:** Use different configurations for different environments  
- **Runtime updates:** Update configuration without rebuilding container images
- **Security:** Protect sensitive data with appropriate access controls
- **Portability:** Make applications portable across different environments

## ConfigMaps vs Secrets

| ConfigMaps | Secrets |
|------------|---------|
| **Non-confidential data** | **Sensitive data** |
| API endpoints, feature flags | Passwords, tokens, certificates |
| Visible in plain text | Base64 encoded + additional security |
| Configuration files, environment variables | Credentials, TLS certificates, SSH keys |

## When to Use Each

**Use ConfigMaps for:**
- Application settings and feature flags
- API endpoints and service URLs
- Configuration files (nginx.conf, app.properties)
- Environment-specific settings
- Non-sensitive environment variables

**Use Secrets for:**
- Database passwords and connection strings
- API keys and authentication tokens
- TLS certificates and private keys
- SSH keys for Git repositories
- Docker registry credentials

## Configuration Patterns

Both ConfigMaps and Secrets can be consumed by pods in multiple ways:

- **Environment variables:** Inject configuration as environment variables
- **Volume mounts:** Mount configuration as files in the container filesystem
- **Command-line arguments:** Pass configuration as arguments to container commands

## Explore Configuration Management

Learn how to manage both types of configuration data:

- **[ConfigMaps](./configmaps)** - Store and manage non-confidential configuration data
- **[Secrets](./secrets)** - Securely handle sensitive information like passwords and certificates

## Key Points to Remember

* ConfigMaps handle non-confidential configuration data
* Secrets provide secure storage for sensitive information
* Both decouple configuration from application code
* Choose the right resource based on data sensitivity
* Both support multiple consumption patterns (env vars, files, args)