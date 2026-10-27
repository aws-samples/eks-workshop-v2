output "server_url" {
  description = "Argo CD server URL published by the capability"
  value       = aws_eks_capability.argocd.configuration[0].argo_cd[0].server_url
}
