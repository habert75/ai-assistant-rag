# Kubernetes Manifests

This directory contains the Kubernetes manifests for deploying the AI Assistant RAG application.

## Files

- `namespace.yaml` - Creates the `ai-assistant-rag` namespace
- `deployment.yaml` - Application deployment configuration
- `service.yaml` - LoadBalancer service to expose the application
- `argocd-application.yaml` - Argo CD application manifest
- `secret.yaml.template` - Template for creating the secret (DO NOT commit secret.yaml)

## Important: Handling Secrets

**Never commit `secret.yaml` to Git!** The actual secret file is ignored by `.gitignore`.

### Setup Secret Before Deployment

1. **Copy the template:**
   ```powershell
   Copy-Item k8s/secret.yaml.template k8s/secret.yaml
   ```

2. **Edit `k8s/secret.yaml` and add your OpenAI API key:**
   ```yaml
   OPENAI_API_KEY: "sk-your-actual-key-here"
   ```

3. **Create the secret manually in Kubernetes:**
   ```powershell
   kubectl apply -f k8s/secret.yaml
   ```

4. **Verify the secret was created:**
   ```powershell
   kubectl get secret -n ai-assistant-rag
   ```

### For Argo CD Deployment

When using Argo CD, the secret is **excluded** from automatic sync. You must:

1. Create the secret manually (as shown above) **before** deploying with Argo CD
2. The secret will persist even if you delete/recreate the Argo CD application
3. To update the secret, edit and reapply `k8s/secret.yaml` manually

### Alternative: Using Sealed Secrets (Production)

For production deployments, consider using [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets) or external secret managers:
- Sealed Secrets (Kubernetes)
- External Secrets Operator
- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault

## Quick Deployment

### Direct kubectl deployment:
```powershell
kubectl apply -f k8s/
```

### Argo CD deployment:
```powershell
# 1. First create the secret manually
kubectl apply -f k8s/secret.yaml

# 2. Then deploy the Argo CD application
kubectl apply -f k8s/argocd-application.yaml
```
