# GitOps CI/CD Platform

A production-grade CI/CD pipeline that automatically builds, tests, scans, and deploys applications to Kubernetes.

## What This Does

When you push code to GitHub:

1. Jenkins automatically builds a Docker image
2. Trivy scans the image for security vulnerabilities
3. Image is pushed to AWS ECR
4. ArgoCD detects the change and deploys to Kubernetes
5. Prometheus monitors the running application
6. Grafana displays dashboards
7. Alerts are sent to Slack

Result: Zero-manual deployments. Everything is automated.

## Prerequisites

- AWS account
- GitHub account
- Docker installed locally
- kubectl installed
- aws-cli configured

## Project Structure

```
gitops-platform/
├── app.py
├── requirements.txt
├── Dockerfile
├── Jenkinsfile
├── helm-chart/
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
└── README.md
```

## Tech Stack

Component | Purpose | Cost
--- | --- | ---
GitHub | Code repository | Free
Jenkins | Build automation | $20/month
Docker | Containerization | Free
Trivy | Security scanning | Free
ECR | Image registry | Free tier
Kubernetes (EKS) | Container orchestration | $25/month
ArgoCD | GitOps deployments | Free
Prometheus | Metrics collection | Free
Grafana | Dashboards | Free
Slack | Notifications | Free

Total Cost: approximately $70-100/month

## How to Use

### Step 1: Set Up AWS

Create EKS cluster:

```bash
aws eks create-cluster \
  --name gitops-demo \
  --region us-east-1 \
  --version 1.28
```

Create ECR repository:

```bash
aws ecr create-repository \
  --repository-name gitops-app
```

### Step 2: Deploy Jenkins

Follow the COMPLETE_GITOPS_GUIDE.md for detailed instructions. This takes approximately 2 hours.

### Step 3: Configure GitHub Webhook

Add webhook to your GitHub repository:

Webhook URL: http://YOUR_JENKINS_IP:8080/github-webhook/

### Step 4: Deploy Application

Push code to GitHub:

```bash
git push origin main
```

Jenkins will automatically build and deploy.

### Step 5: View Dashboards

Access Grafana:

```bash
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Open http://localhost:3000

Default credentials: admin / prom-operator

## Application Details

The Flask application has three endpoints:

GET /health - Health check endpoint
GET /data - Returns sample data
GET /metrics - Prometheus metrics endpoint

### Test Locally

Install dependencies:

```bash
pip install -r requirements.txt
```

Run the application:

```bash
python app.py
```

Test the endpoints:

```bash
curl http://localhost:5000/health
curl http://localhost:5000/metrics
```

### Build Docker Image

Build:

```bash
docker build -t gitops-app:1.0 .
```

Run:

```bash
docker run -p 5000:5000 gitops-app:1.0
```

Push to ECR:

```bash
docker tag gitops-app:1.0 YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/gitops-app:1.0
docker push YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/gitops-app:1.0
```

## CI/CD Pipeline Stages

The Jenkinsfile automatically runs these stages:

1. Checkout - Pull code from GitHub
2. Build - Build Docker image
3. Test - Run unit tests
4. Security Scan - Trivy scans for CVEs
5. Push to ECR - Upload image to registry
6. Update Config - Commit new image tag to Git
7. Deploy - ArgoCD deploys to Kubernetes
8. Verify - Smoke tests on deployed app
9. Notify - Send result to Slack

## Monitoring and Alerts

### Key Metrics Tracked

- Request rate (requests per second)
- Response time (p50, p99)
- Error rate (percentage)
- CPU usage
- Memory usage

### Default Alert Rules

- High CPU: greater than 70% for 5 minutes
- High memory: greater than 80%
- High error rate: greater than 5%
- Pod not ready: for more than 5 minutes

### View Metrics

Port-forward to Prometheus:

```bash
kubectl port-forward -n monitoring svc/prometheus 9090:9090
```

Open http://localhost:9090

Search for metric: app_requests_total

## Configuration

### Update Image in Kubernetes

Edit helm values:

```bash
vim helm-chart/values.yaml
```

Update the image tag:

```yaml
image:
  tag: v1.2.3
```

Commit and push:

```bash
git add helm-chart/values.yaml
git commit -m "Update app to v1.2.3"
git push origin main
```

ArgoCD will automatically deploy the new version.

### Scale Application

Edit replicas in values.yaml:

```yaml
replicas: 5
```

Push to Git:

```bash
git push origin main
```

The application will automatically scale to 5 pods.

### Change Resources

Edit values.yaml:

```yaml
resources:
  limits:
    cpu: 500m
    memory: 512Mi
```

Push and the changes will be automatically applied.

## Troubleshooting

### Build Fails

Check Jenkins logs:

```bash
kubectl logs -n jenkins <pod-name>
```

Check Docker build locally:

```bash
docker build -t test:latest .
```

Check requirements.txt:

```bash
pip install -r requirements.txt
```

### Deployment Fails

Check ArgoCD status:

```bash
argocd app get gitops-app
```

Check pod logs:

```bash
kubectl logs -n production <pod-name>
```

Check if image exists in ECR:

```bash
aws ecr describe-images --repository-name gitops-app
```

### Prometheus Not Scraping

Check if metrics endpoint is working:

```bash
kubectl port-forward -n production svc/gitops-app 5000:5000
curl http://localhost:5000/metrics
```

Check Prometheus configuration:

```bash
kubectl get cm -n monitoring prometheus-server -o yaml
```

### Slack Not Getting Alerts

Check Alertmanager configuration:

```bash
kubectl get secret -n monitoring alertmanager-config -o yaml
```

Test webhook manually:

```bash
curl -X POST https://hooks.slack.com/... -d '{"text":"test"}'
```

## Scaling This Platform

### Add More Services

Create a Helm chart for the new service:

```bash
helm create helm-chart-2
```

Add Jenkins build step for the new service and an ArgoCD application for it. Both will auto-deploy independently.

### Add More Environments

Create separate values files for dev, staging, and production:

```bash
helm install gitops-app ./helm-chart -f values-dev.yaml
helm install gitops-app ./helm-chart -f values-prod.yaml
```

Different configurations can be used for each environment.

### Multi-Region Deployment

Deploy EKS clusters in multiple regions. Each region has its own ArgoCD instance. All watch the same Git repository and auto-deploy to all regions.

## Security Best Practices

Implemented:

- Trivy security scanning on images
- Non-root user in containers
- Health checks on pods
- Network policies on Kubernetes
- IAM roles for Jenkins

Not Implemented (add later):

- TLS/HTTPS for services
- Secrets management (Sealed Secrets)
- Pod security policies
- Resource quotas per namespace
- Network ingress/egress rules

## Cost Breakdown

Monthly costs:

EKS cluster: $25
EC2 (Jenkins): $20
Load Balancer: $16
Storage: $5
Data transfer: $5
Total: approximately $70

For 6 weeks: $70 x 1.5 = approximately $105

This is a reasonable investment for learning production-grade infrastructure.


## License

MIT - Use freely and modify as needed
