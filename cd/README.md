# Argo CD Deployment Guide

This guide explains how to deploy the AI Assistant RAG application using Argo CD, following the same pattern as the streamlit_ploter application.

## Directory Structure

```
ai-assistant-rag/
├── cd/                          # Continuous Deployment manifests
│   ├── application.yaml         # Argo CD Application definition
│   ├── deployment.yaml          # K8s Deployment & Service (NO SECRETS)
│   ├── secret.yaml             # IGNORED - Contains actual API key
│   └── secret.yaml.template    # Safe template to commit
├── app.py
├── Dockerfile
└── ...
```

## ⚠️ IMPORTANT: Secret Management

**The `cd/secret.yaml` file is ignored by Git and will NOT be pushed to GitHub.**

### Setup Secret

1. **Copy the template:**
   ```powershell
   Copy-Item cd/secret.yaml.template cd/secret.yaml
   ```

2. **Edit `cd/secret.yaml` and add your OpenAI API key**

3. **Create the secret in Kubernetes BEFORE deploying:**
   ```powershell
   kubectl apply -f cd/secret.yaml
   ```

## Option 1: Git Repository (Recommended for Production)

### Step 1: Push to GitHub

```powershell
cd "C:\Users\Admin\Documents\Training\Argo CD\ai-assistant-rag"
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR-USERNAME/YOUR-REPO.git
git push -u origin main
```

### Step 2: Update application.yaml

Edit `cd/application.yaml` and uncomment the Git repository section:

```yaml
source:
  repoURL: https://github.com/YOUR-USERNAME/YOUR-REPO
  targetRevision: HEAD
  path: "cd"
```

### Step 3: Configure API Key

Edit `cd/deployment.yaml` and update the secret:

```yaml
stringData:
  OPENAI_API_KEY: "sk-your-actual-api-key-here"
```

### Step 4: Apply Argo CD Application

```powershell
kubectl apply -f cd/application.yaml
```

### Step 5: Monitor Deployment

```powershell
# Check application status
kubectl get application -n argocd

# Watch the deployment
kubectl get pods -n ai-assistant-rag -w
```

## Option 2: Local Development (Docker Desktop)

For local development without Git, Argo CD needs to access your local filesystem.

### Method A: Using Argo CD with Local Path

This requires configuring Argo CD to mount your local directory, which is complex with Docker Desktop.

**Better alternative:** Use direct kubectl deployment for local development:

```powershell
# Build and deploy directly
docker build -t ai-assistant-rag:latest .
kubectl apply -f cd/deployment.yaml
```

### Method B: Push Image to Docker Hub

```powershell
# Tag the image
docker tag ai-assistant-rag:latest YOUR-DOCKERHUB-USERNAME/ai-assistant-rag:v1.0

# Push to Docker Hub
docker push YOUR-DOCKERHUB-USERNAME/ai-assistant-rag:v1.0
```

Then update `cd/deployment.yaml`:

```yaml
containers:
- name: ai-assistant-rag
  image: YOUR-DOCKERHUB-USERNAME/ai-assistant-rag:v1.0
  imagePullPolicy: Always
```

And deploy with Argo CD as in Option 1.

## Deployment Workflow

### Initial Deployment

```powershell
# 1. Ensure Argo CD is running
kubectl get pods -n argocd

# 2. Build Docker image
docker build -t ai-assistant-rag:latest .

# 3. Update API key in cd/deployment.yaml (if not done)
# Edit the file manually

# 4. Create Argo CD application
kubectl apply -f cd/application.yaml

# 5. Verify deployment
kubectl get application -n argocd
kubectl get pods -n ai-assistant-rag
```

### Accessing the Application

```powershell
# Get service details
kubectl get svc -n ai-assistant-rag

# Access via LoadBalancer
# http://localhost:8503
```

### Updating the Application

When you make changes:

```powershell
# 1. Update code
# Edit your files...

# 2. Rebuild image
docker build -t ai-assistant-rag:latest .

# 3. If using local image, restart deployment
kubectl rollout restart deployment/ai-assistant-rag -n ai-assistant-rag

# 4. If using Git + Docker Hub
git add .
git commit -m "Update application"
git push

# Rebuild and push image with new version
docker tag ai-assistant-rag:latest YOUR-USERNAME/ai-assistant-rag:v1.1
docker push YOUR-USERNAME/ai-assistant-rag:v1.1

# Update cd/deployment.yaml with new image tag and push
git add cd/deployment.yaml
git commit -m "Update to v1.1"
git push

# Argo CD will automatically sync (if automated sync is enabled)
```

## Argo CD UI Access

### Check if Argo CD UI is exposed

```powershell
kubectl get svc -n argocd
```

### Port Forward to Access UI

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Then access: `https://localhost:8080`

### Get Admin Password

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | ForEach-Object { [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($_)) }
```

Login with:
- Username: `admin`
- Password: (from above command)

## Comparing with streamlit_ploter Setup

Your streamlit_ploter uses:
- **Git repository**: https://github.com/habert75/streamlit_ploter
- **Docker Hub image**: habert/streamlit-plotter:v1.0
- **Automated sync**: enabled

To match this pattern for ai-assistant-rag:

1. Push code to GitHub
2. Build and push image to Docker Hub: `habert/ai-assistant-rag:v1.0`
3. Update `cd/deployment.yaml` with the Docker Hub image
4. Update `cd/application.yaml` with your GitHub repo URL
5. Apply: `kubectl apply -f cd/application.yaml`

## Troubleshooting

### Application not syncing

```powershell
# Check application status
kubectl describe application ai-assistant-rag-app -n argocd

# Force sync
kubectl patch application ai-assistant-rag-app -n argocd --type merge -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"normal"}}}'
```

### Image pull errors

```powershell
# Verify image exists locally
docker images | Select-String ai-assistant-rag

# Or verify image exists in Docker Hub
# Visit: https://hub.docker.com/r/YOUR-USERNAME/ai-assistant-rag
```

### API Key issues

```powershell
# Check secret
kubectl get secret openai-api-key -n ai-assistant-rag -o yaml

# Update secret
kubectl delete secret openai-api-key -n ai-assistant-rag
kubectl apply -f cd/deployment.yaml
```

## Cleanup

### Remove Application

```powershell
# Delete Argo CD application (this will remove all resources)
kubectl delete -f cd/application.yaml

# Or manually delete namespace
kubectl delete namespace ai-assistant-rag
```

## Quick Reference Commands

```powershell
# Build image
docker build -t ai-assistant-rag:latest .

# Deploy with Argo CD
kubectl apply -f cd/application.yaml

# Check application
kubectl get application -n argocd
kubectl get pods -n ai-assistant-rag

# View logs
kubectl logs -n ai-assistant-rag -l app=ai-assistant-rag -f

# Restart deployment
kubectl rollout restart deployment/ai-assistant-rag -n ai-assistant-rag

# Access UI
kubectl get svc -n ai-assistant-rag
# Then open: http://localhost:8503
```
