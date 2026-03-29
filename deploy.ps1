# deploy.ps1 - Automated deployment script for AI Assistant RAG
# Usage: .\deploy.ps1 -Version v1.0.4 [-Message "Optional commit message"]

param(
    [Parameter(Mandatory=$true, HelpMessage="Version tag (e.g., v1.0.4)")]
    [string]$Version,
    
    [Parameter(Mandatory=$false)]
    [string]$Message = "Deploy version $Version",
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipGit = $false
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  🚀 AI Assistant RAG - Automated Deployment Script       ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "Version: $Version" -ForegroundColor White
Write-Host "Message: $Message" -ForegroundColor White
Write-Host ""

# Validate version format (should be like v1.0.0)
if ($Version -notmatch '^v\d+\.\d+\.\d+$') {
    Write-Host "⚠️  Warning: Version format should be 'vX.Y.Z' (e.g., v1.0.4)" -ForegroundColor Yellow
    $continue = Read-Host "Continue anyway? (y/n)"
    if ($continue -ne 'y') { exit 1 }
}

# Step 1: Build Docker image
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "📦 Step 1/7: Building Docker image..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
docker build -t habert/ai-assistant-rag:$Version .
if ($LASTEXITCODE -ne 0) { 
    Write-Host "❌ Docker build failed!" -ForegroundColor Red
    exit 1 
}
Write-Host "✅ Image built successfully" -ForegroundColor Green

# Step 2: Tag as latest
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "🏷️  Step 2/7: Tagging as latest..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
docker tag habert/ai-assistant-rag:$Version habert/ai-assistant-rag:latest
Write-Host "✅ Tagged as latest" -ForegroundColor Green

# Step 3: Push versioned tag to Docker Hub
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "☁️  Step 3/7: Pushing $Version to Docker Hub..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
docker push habert/ai-assistant-rag:$Version
if ($LASTEXITCODE -ne 0) { 
    Write-Host "❌ Docker push failed!" -ForegroundColor Red
    exit 1 
}
Write-Host "✅ Version $Version pushed successfully" -ForegroundColor Green

# Step 4: Push latest tag
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "☁️  Step 4/7: Pushing latest tag to Docker Hub..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
docker push habert/ai-assistant-rag:latest
if ($LASTEXITCODE -ne 0) { 
    Write-Host "⚠️  Warning: Could not push latest tag" -ForegroundColor Yellow
}
else {
    Write-Host "✅ Latest tag pushed successfully" -ForegroundColor Green
}

# Step 5: Update deployment.yaml
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "📝 Step 5/7: Updating deployment.yaml..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

$deploymentFile = "cd/deployment.yaml"
if (-not (Test-Path $deploymentFile)) {
    Write-Host "❌ deployment.yaml not found at $deploymentFile" -ForegroundColor Red
    exit 1
}

$content = Get-Content $deploymentFile -Raw
$oldImage = $content -match 'image:\s+habert/ai-assistant-rag:(.+)' | Out-Null
$oldVersion = $matches[1]

if ($oldVersion) {
    Write-Host "   Old version: $oldVersion" -ForegroundColor DarkGray
}

$content = $content -replace 'image:\s+habert/ai-assistant-rag:.+', "image: habert/ai-assistant-rag:$Version"
Set-Content $deploymentFile -Value $content -NoNewline
Write-Host "✅ deployment.yaml updated with version $Version" -ForegroundColor Green

if ($SkipGit) {
    Write-Host ""
    Write-Host "⏭️  Skipping Git operations (SkipGit flag set)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🎉 Docker image deployed. Manually commit and push to trigger ArgoCD:" -ForegroundColor Cyan
    Write-Host "   git add cd/deployment.yaml" -ForegroundColor White
    Write-Host "   git commit -m '$Message'" -ForegroundColor White
    Write-Host "   git push" -ForegroundColor White
    exit 0
}

# Step 6: Commit and push to Git
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "🔄 Step 6/7: Committing to Git..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

git add cd/deployment.yaml
if ($LASTEXITCODE -ne 0) { 
    Write-Host "❌ Git add failed!" -ForegroundColor Red
    exit 1 
}

git commit -m "$Message"
if ($LASTEXITCODE -ne 0) { 
    Write-Host "⚠️  Warning: Git commit failed (maybe no changes?)" -ForegroundColor Yellow
}
else {
    Write-Host "✅ Changes committed" -ForegroundColor Green
}

git push
if ($LASTEXITCODE -ne 0) { 
    Write-Host "❌ Git push failed!" -ForegroundColor Red
    Write-Host "   Please push manually: git push" -ForegroundColor Yellow
    exit 1 
}
Write-Host "✅ Changes pushed to GitHub" -ForegroundColor Green

# Step 7: Wait and monitor deployment
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
Write-Host "⏳ Step 7/7: Monitoring ArgoCD deployment..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

Write-Host "   Waiting 10 seconds for ArgoCD to detect changes..." -ForegroundColor DarkGray
Start-Sleep -Seconds 10

Write-Host "   Checking deployment status..." -ForegroundColor DarkGray
kubectl rollout status deployment ai-assistant-rag -n ai-assistant-rag --timeout=120s
if ($LASTEXITCODE -ne 0) { 
    Write-Host "⚠️  Warning: Deployment status check timed out or failed" -ForegroundColor Yellow
    Write-Host "   Check manually: kubectl get pods -n ai-assistant-rag" -ForegroundColor Yellow
}
else {
    Write-Host "✅ Deployment completed successfully" -ForegroundColor Green
}

# Final status
Write-Host ""
Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║              🎉 DEPLOYMENT SUCCESSFUL!                    ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Current Status:" -ForegroundColor Cyan
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
kubectl get pods -n ai-assistant-rag
Write-Host ""
kubectl get svc ai-assistant-rag-svc -n ai-assistant-rag
Write-Host ""
Write-Host "🌐 Access your application at:" -ForegroundColor Cyan
Write-Host "   http://localhost:8503" -ForegroundColor White
Write-Host ""
Write-Host "📋 Useful commands:" -ForegroundColor Cyan
Write-Host "   View logs:  kubectl logs -n ai-assistant-rag -l app=ai-assistant-rag -f" -ForegroundColor DarkGray
Write-Host "   Check pods: kubectl get pods -n ai-assistant-rag" -ForegroundColor DarkGray
Write-Host "   ArgoCD app: kubectl get application ai-assistant-rag-app -n argocd" -ForegroundColor DarkGray
Write-Host ""
