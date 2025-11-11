---
title: Configuration
sidebar_position: 60
---

# Configuration

Applications often require configuration data - from environment-specific settings like API endpoints to sensitive credentials like database passwords. Kubernetes provides two core resources to manage configuration data:

**ConfigMaps** - for non-confidentail configuration data
**Secrets** - for sensitive information like passwords, tokens, and certificates

Modern applications run across multiple environments and often scale dynamically.

Kubernetes configuration resources make this easy by allowing you to:
- **Separate configuration from code** — so you can deploy the same container everywhere
- **Use environment-specific settings** without modifying application images
- **Update configuration at runtime** without restarting or rebuilding images
- **Enhance security** by limiting access to sensitive values
- **Improve portability** across clusters and cloud providers

## ConfigMaps vs Secrets

| Category           | ConfigMaps                                 | Secrets                                       |
| ------------------ | ------------------------------------------ | --------------------------------------------- |
| **Purpose**        | Store non-confidential configuration       | Store sensitive data                          |
| **Examples**       | API endpoints, feature flags, config files | Passwords, tokens, certificates               |
| **Data format**    | Plain text                                 | Base64 encoded |
| **Visibility**     | Readable by all with access                | Access restricted via RBAC                    |
| **Security level** | Low                                        | High                                          |

## When to Use Each

**Use ConfigMaps for:**
- Application settings and feature flags
- Service URLs and API endpoints
- Configuration files (`nginx.conf`, `application.yaml`)
- Environment-specific parameters

**Use Secrets for:**
- Database credentials
- API keys and tokens
- TLS certificates and private keys
- Container registry credentials

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
* Secrets securely store sensitive information
* Both decouple configuration from application code
* Choose the right resource based on data sensitivity
* Both support multiple consumption patterns (env vars, files, args)