# Kubernetes Deployment Guide

This guide explains how to deploy the AI Assistant RAG application to your Kubernetes cluster.

## Prerequisites

1. **Docker Desktop** with Kubernetes enabled
   - Open Docker Desktop → Settings → Kubernetes → Enable Kubernetes
2. **kubectl** CLI tool installed
3. **Docker image** built locally
4. **OpenAI API Key**

## Quick Start

### Step 1: Build the Docker Image

```powershell
cd "C:\Users\Admin\Documents\Training\Argo CD\ai-assistant-rag"
docker build -t ai-assistant-rag:latest .
```

### Step 2: Configure Your API Key

Edit `k8s/secret.yaml` and replace `your_openai_api_key_here` with your actual OpenAI API key.

### Step 3: Deploy to Kubernetes

```powershell
# Apply all manifests at once
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
```

Or apply all at once:

```powershell
kubectl apply -f k8s/
```

### Step 4: Verify Deployment

```powershell
# Check if pods are running
kubectl get pods -n ai-assistant-rag

# Check service status
kubectl get svc -n ai-assistant-rag

# View logs
kubectl logs -n ai-assistant-rag -l app=ai-assistant-rag -f
```

### Step 5: Access the Application

For Docker Desktop Kubernetes, the LoadBalancer service will be accessible at:

```
http://localhost:8503
```

## Deployment Options

### Option 1: Direct Kubectl Deployment (Recommended for Quick Start)

Follow the Quick Start steps above.

### Option 2: Argo CD GitOps Deployment

If you have Argo CD installed and want to use GitOps:

1. **Push your code to a Git repository**

2. **Update the Argo CD application manifest**
   
   Edit `k8s/argocd-application.yaml` and update:
   - `repoURL`: Your Git repository URL
   - `targetRevision`: Branch name (e.g., `main` or `master`)

3. **Apply the Argo CD application**
   
   ```powershell
   kubectl apply -f k8s/argocd-application.yaml
   ```

4. **Monitor the deployment**
   
   ```powershell
   # Using kubectl
   kubectl get application -n argocd
   
   # Or use Argo CD UI
   # Access the Argo CD dashboard and check the application status
   ```

## Manifest Overview

### namespace.yaml
Creates a dedicated namespace `ai-assistant-rag` for the application.

### secret.yaml
Stores the OpenAI API key securely. **Important**: Update this file with your actual API key before deploying.

### deployment.yaml
Defines the application deployment with:
- 1 replica
- Resource limits (512Mi-1Gi memory, 250m-1000m CPU)
- Liveness and readiness probes
- Environment variable injection from the secret
- EmptyDir volume for document uploads

### service.yaml
Exposes the application using a LoadBalancer service on port 8503.

### argocd-application.yaml (Optional)
Argo CD application manifest for GitOps deployment.

## Troubleshooting

### Pods Not Starting

```powershell
# Check pod events
kubectl describe pod -n ai-assistant-rag -l app=ai-assistant-rag

# Check logs
kubectl logs -n ai-assistant-rag -l app=ai-assistant-rag
```

### Image Pull Errors

If you see "ImagePullBackOff" errors, it means Kubernetes can't find the image. Ensure:
- The image is built locally: `docker images | Select-String ai-assistant-rag`
- The `imagePullPolicy` is set to `IfNotPresent` in deployment.yaml

### API Key Issues

If the application can't access the OpenAI API:
- Verify the secret is created: `kubectl get secret -n ai-assistant-rag`
- Check the secret content: `kubectl get secret openai-api-key -n ai-assistant-rag -o yaml`

### Service Not Accessible

```powershell
# Check service details
kubectl get svc -n ai-assistant-rag -o wide

# Port forward as alternative
kubectl port-forward -n ai-assistant-rag svc/ai-assistant-rag 8503:8503
```

Then access at: `http://localhost:8503`

## Updating the Application

### Update Image

```powershell
# Rebuild the image
docker build -t ai-assistant-rag:latest .

# Restart the deployment to pick up the new image
kubectl rollout restart deployment/ai-assistant-rag -n ai-assistant-rag

# Monitor the rollout
kubectl rollout status deployment/ai-assistant-rag -n ai-assistant-rag
```

### Update Configuration

```powershell
# After editing manifests
kubectl apply -f k8s/

# Or specific manifest
kubectl apply -f k8s/deployment.yaml
```

## Scaling

```powershell
# Scale to multiple replicas
kubectl scale deployment/ai-assistant-rag -n ai-assistant-rag --replicas=3

# Check scaling status
kubectl get pods -n ai-assistant-rag
```

**Note**: Document uploads use emptyDir volumes, so each pod has its own storage. Consider using persistent volumes if you need shared storage across replicas.

## Cleanup

### Remove the Application

```powershell
# Delete all resources
kubectl delete -f k8s/

# Or delete namespace (removes everything)
kubectl delete namespace ai-assistant-rag
```

### Remove Argo CD Application (if used)

```powershell
kubectl delete -f k8s/argocd-application.yaml
```

## Production Considerations

For production deployments, consider:

1. **Persistent Storage**: Replace emptyDir with PersistentVolumeClaim for document storage
2. **Ingress**: Use an Ingress controller instead of LoadBalancer for better routing
3. **TLS**: Add TLS certificates for HTTPS
4. **Resource Limits**: Adjust based on actual usage patterns
5. **High Availability**: Increase replicas and add pod anti-affinity rules
6. **Secrets Management**: Use external secret managers (e.g., Azure Key Vault, AWS Secrets Manager)
7. **Monitoring**: Add Prometheus metrics and Grafana dashboards
8. **Backup**: Implement backup strategies for persistent data

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Docker Desktop Kubernetes](https://docs.docker.com/desktop/kubernetes/)
- [Argo CD Documentation](https://argo-cd.readthedocs.io/)
- [Streamlit Deployment](https://docs.streamlit.io/knowledge-base/tutorials/deploy)
