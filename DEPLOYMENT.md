# AI Assistant RAG - Deployment Workflow Guide

## 🎯 Recommended GitOps Workflow (Production-Ready)

This guide explains the proper way to deploy updates to your AI Assistant RAG application using versioned Docker images and GitOps principles with ArgoCD.

---

## 📋 Prerequisites

- Docker installed and logged in to Docker Hub
- Kubernetes cluster running (Docker Desktop, Minikube, etc.)
- ArgoCD installed and configured
- Git repository connected to ArgoCD

---

## 🚀 Complete Deployment Workflow

### Step 1: Make Your Code Changes

Edit your application files (e.g., `app.py`, `rag.py`, etc.)

### Step 2: Build and Push Versioned Docker Image

**Important**: Always use semantic versioning (v1.0.0, v1.0.1, v1.1.0, etc.) instead of `:latest`

```powershell
# Increment version number for each release
$VERSION = "v1.0.3"

# Build the image
docker build -t habert/ai-assistant-rag:$VERSION .

# Also tag as latest (optional)
docker tag habert/ai-assistant-rag:$VERSION habert/ai-assistant-rag:latest

# Push both tags
docker push habert/ai-assistant-rag:$VERSION
docker push habert/ai-assistant-rag:latest
```

### Step 3: Update Kubernetes Manifest

Edit `cd/deployment.yaml` and update the image tag:

```yaml
spec:
  containers:
  - name: ai-assistant-rag
    image: habert/ai-assistant-rag:v1.0.3  # Update version here
    imagePullPolicy: Always
```

### Step 4: Commit and Push to Git

```powershell
git add cd/deployment.yaml
git commit -m "Deploy version v1.0.3 - [describe changes]"
git push
```

### Step 5: Watch ArgoCD Auto-Sync

ArgoCD will automatically detect the Git change and deploy the new version:

```powershell
# Watch ArgoCD application status
kubectl get application ai-assistant-rag-app -n argocd -w

# Watch pods rolling out
kubectl get pods -n ai-assistant-rag -w

# Check deployment status
kubectl rollout status deployment ai-assistant-rag -n ai-assistant-rag
```

### Step 6: Verify Deployment

```powershell
# Check running pods
kubectl get pods -n ai-assistant-rag

# View pod details (including image version)
kubectl describe pod -n ai-assistant-rag -l app=ai-assistant-rag

# Get service URL
kubectl get svc ai-assistant-rag-svc -n ai-assistant-rag
```

Access the app at: **http://localhost:8503**

---

## ⚡ Quick Reference Commands

### Build, Push, and Deploy (One-liner)

```powershell
# Set version
$VERSION = "v1.0.3"

# Build and push
docker build -t habert/ai-assistant-rag:$VERSION . ; docker push habert/ai-assistant-rag:$VERSION

# Update deployment file (manual edit required)
# Then commit and push
git add cd/deployment.yaml ; git commit -m "Deploy $VERSION" ; git push
```

### Check Application Status

```powershell
# ArgoCD application health
kubectl get application -n argocd | Select-String "assistant"

# Pod status
kubectl get pods -n ai-assistant-rag

# Logs
kubectl logs -n ai-assistant-rag -l app=ai-assistant-rag --tail=100 -f

# Service endpoint
kubectl get svc ai-assistant-rag-svc -n ai-assistant-rag
```

### Manual Sync (if auto-sync is disabled)

```powershell
# Sync via ArgoCD CLI
argocd app sync ai-assistant-rag-app

# Or via kubectl
kubectl patch application ai-assistant-rag-app -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"manual"},"sync":{}}}'
```

---

## 🐛 Troubleshooting

### Issue: Changes not reflected after Git push

**Causes:**
1. Using `:latest` tag with `imagePullPolicy: IfNotPresent`
2. ArgoCD hasn't synced yet
3. Image not pushed to Docker Hub

**Solutions:**
```powershell
# Check if ArgoCD sees the change
kubectl get application ai-assistant-rag-app -n argocd -o yaml | Select-String "OutOfSync"

# Force ArgoCD to sync
argocd app sync ai-assistant-rag-app

# Force pod restart (last resort)
kubectl rollout restart deployment ai-assistant-rag -n ai-assistant-rag
```

### Issue: "ImagePullBackOff" or "ErrImagePull"

**Cause**: Kubernetes cannot pull the image from Docker Hub

**Solutions:**
```powershell
# Check if image exists on Docker Hub
docker pull habert/ai-assistant-rag:v1.0.3

# Check Docker Hub credentials (if private repo)
kubectl get secret -n ai-assistant-rag

# Check pod events
kubectl describe pod -n ai-assistant-rag -l app=ai-assistant-rag
```

### Issue: Ctrl+C doesn't stop local Streamlit

**Solution:**
```powershell
# Find and kill Python process
Get-Process | Where-Object {$_.ProcessName -like "*python*"} | Stop-Process -Force

# Or use Ctrl+Break instead of Ctrl+C
```

### Issue: ArgoCD keeps reverting manual changes

**Cause**: ArgoCD has auto-sync and self-heal enabled

**Solution**: This is expected GitOps behavior! Make changes in Git, not directly in Kubernetes.

```powershell
# To temporarily disable self-healing (not recommended)
kubectl patch application ai-assistant-rag-app -n argocd --type=merge -p '{"spec":{"syncPolicy":{"automated":{"selfHeal":false}}}}'
```

---

## 🎓 Why Version Your Docker Images?

### ❌ Problems with `:latest` tag

1. **No Git Tracking**: Git only tracks `image: app:latest`, not which version of the Docker image is deployed
2. **No Rollback**: Cannot easily roll back to a previous version
3. **Cache Issues**: `imagePullPolicy: IfNotPresent` won't pull updated `:latest` images
4. **No Audit Trail**: Can't tell which code version is running from Git history
5. **ArgoCD Confusion**: ArgoCD won't detect image changes, only YAML changes

### ✅ Benefits of Versioned Images

1. **Full Traceability**: Know exactly which code version is deployed
2. **Easy Rollback**: `kubectl rollout undo` or change Git tag
3. **GitOps Compliance**: Git is the single source of truth
4. **Clear History**: Git log shows deployment timeline
5. **ArgoCD Integration**: Detects changes and auto-syncs

---

## 🤖 Automated Deployment Script

Save this as `deploy.ps1` in your project root:

```powershell
# deploy.ps1 - Automated deployment script

param(
    [Parameter(Mandatory=$true)]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "Deploy version $Version"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Starting deployment of version $Version" -ForegroundColor Green

# Step 1: Build Docker image
Write-Host "`n📦 Building Docker image..." -ForegroundColor Yellow
docker build -t habert/ai-assistant-rag:$Version .
if ($LASTEXITCODE -ne 0) { exit 1 }

# Step 2: Push to Docker Hub
Write-Host "`n☁️  Pushing to Docker Hub..." -ForegroundColor Yellow
docker push habert/ai-assistant-rag:$Version
if ($LASTEXITCODE -ne 0) { exit 1 }

# Also push as latest
docker tag habert/ai-assistant-rag:$Version habert/ai-assistant-rag:latest
docker push habert/ai-assistant-rag:latest

# Step 3: Update deployment.yaml
Write-Host "`n📝 Updating deployment.yaml..." -ForegroundColor Yellow
$deploymentFile = "cd/deployment.yaml"
$content = Get-Content $deploymentFile -Raw
$content = $content -replace 'image: habert/ai-assistant-rag:v[\d.]+', "image: habert/ai-assistant-rag:$Version"
Set-Content $deploymentFile -Value $content

# Step 4: Commit and push to Git
Write-Host "`n🔄 Committing to Git..." -ForegroundColor Yellow
git add cd/deployment.yaml
git commit -m "$Message"
git push
if ($LASTEXITCODE -ne 0) { exit 1 }

# Step 5: Wait for ArgoCD to sync
Write-Host "`n⏳ Waiting for ArgoCD to sync..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Step 6: Monitor deployment
Write-Host "`n👀 Monitoring deployment..." -ForegroundColor Yellow
kubectl rollout status deployment ai-assistant-rag -n ai-assistant-rag --timeout=120s

# Step 7: Show status
Write-Host "`n✅ Deployment complete!" -ForegroundColor Green
Write-Host "`n📊 Current status:" -ForegroundColor Cyan
kubectl get pods -n ai-assistant-rag
kubectl get svc ai-assistant-rag-svc -n ai-assistant-rag

Write-Host "`n🌐 Access your app at: http://localhost:8503" -ForegroundColor Green
```

### Usage:

```powershell
# Deploy version v1.0.4
.\deploy.ps1 -Version v1.0.4

# Deploy with custom commit message
.\deploy.ps1 -Version v1.0.5 -Message "Fix: Improved RAG query handling"
```

---

## 📊 Current Setup

- **Docker Hub Repository**: `habert/ai-assistant-rag`
- **GitHub Repository**: `https://github.com/habert75/ai-assistant-rag`
- **ArgoCD Path**: `cd/`
- **Namespace**: `ai-assistant-rag`
- **Service Port**: 8503
- **Access URL**: http://localhost:8503

---

## 🔗 Additional Resources

- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Docker Image Tagging Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitOps Principles](https://opengitops.dev/)

---

## 📞 Quick Help

**Need to quickly update without versioning?**
```powershell
docker build -t habert/ai-assistant-rag:latest .
docker push habert/ai-assistant-rag:latest
kubectl rollout restart deployment ai-assistant-rag -n ai-assistant-rag
```
⚠️ This bypasses GitOps and should only be used for testing!
