# 🚀 Quick Reference - AI Assistant RAG Deployment

## ⚡ Super Quick Deploy (One Command)
```powershell
.\deploy.ps1 -Version v1.0.5 -Message "Fix: Updated RAG logic"
```

---

## 📋 Manual Step-by-Step

### 1. Build & Push
```powershell
$VERSION = "v1.0.5"
docker build -t habert/ai-assistant-rag:$VERSION .
docker push habert/ai-assistant-rag:$VERSION
```

### 2. Update Manifest
Edit `cd/deployment.yaml`:
```yaml
image: habert/ai-assistant-rag:v1.0.5  # Change version here
```

### 3. Commit & Push
```powershell
git add cd/deployment.yaml
git commit -m "Deploy v1.0.5"
git push
```

### 4. Monitor
```powershell
kubectl rollout status deployment ai-assistant-rag -n ai-assistant-rag
```

---

## 🔍 Status Commands

```powershell
# Check pods
kubectl get pods -n ai-assistant-rag

# View logs
kubectl logs -n ai-assistant-rag -l app=ai-assistant-rag -f

# Check ArgoCD app
kubectl get application -n argocd | Select-String "assistant"

# Get service URL
kubectl get svc ai-assistant-rag-svc -n ai-assistant-rag
```

---

## 🐛 Quick Fixes

### Changes not showing up?
```powershell
kubectl rollout restart deployment ai-assistant-rag -n ai-assistant-rag
```

### Force ArgoCD sync
```powershell
argocd app sync ai-assistant-rag-app
```

### Kill stuck local Streamlit
```powershell
Get-Process | Where-Object {$_.ProcessName -like "*python*"} | Stop-Process -Force
```

### View pod details
```powershell
kubectl describe pod -n ai-assistant-rag -l app=ai-assistant-rag
```

---

## 🌐 Access URLs

- **Local App**: http://localhost:8503
- **Docker Hub**: https://hub.docker.com/r/habert/ai-assistant-rag
- **GitHub**: https://github.com/habert75/ai-assistant-rag

---

## 📌 Important Notes

✅ **Always use versioned tags** (v1.0.x) instead of `:latest`  
✅ **Commit deployment.yaml changes** to trigger ArgoCD  
✅ **Wait for ArgoCD** to auto-sync (takes ~10-30 seconds)  
❌ **Don't use kubectl directly** for changes (breaks GitOps)  
❌ **Don't use Ctrl+C** to stop local Streamlit (use Ctrl+Break or close terminal)

---

## 🎯 Version Numbering

- **v1.0.x** - Patch (bug fixes, small changes)
- **v1.x.0** - Minor (new features, backwards compatible)
- **vx.0.0** - Major (breaking changes)

Example: `v1.0.1` → `v1.0.2` → `v1.1.0` → `v2.0.0`
