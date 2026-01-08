@echo off
echo ============================================
echo 🚀 STARTING ALL KUBERNETES SERVICES
echo ============================================
echo.

echo Starting ArgoCD (GitOps Platform)...
start "ArgoCD" kubectl port-forward -n argocd svc/argocd-server 8082:80 --kubeconfig infrastructure\terraform\k3d-config

timeout /t 2 /nobreak > nul

echo Starting Grafana (Monitoring Dashboards)...
start "Grafana" kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 --kubeconfig infrastructure\terraform\k3d-config

timeout /t 2 /nobreak > nul

echo Starting Prometheus (Metrics Collection)...
start "Prometheus" kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9092:9090 --kubeconfig infrastructure\terraform\k3d-config

timeout /t 2 /nobreak > nul

echo Starting Alertmanager (Alert Management)...
start "Alertmanager" kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9094:9093 --kubeconfig infrastructure\terraform\k3d-config

echo.
echo ============================================
echo ✅ ALL SERVICES STARTED!
echo ============================================
echo.
echo 🌐 Access URLs:
echo    ArgoCD:      http://localhost:8082
echo    Grafana:     http://localhost:3000
echo    Prometheus:  http://localhost:9092
echo    Alertmanager: http://localhost:9094
echo.
echo 🔐 To get credentials, run these commands in WSL or PowerShell with terraform:
echo    cd infrastructure/terraform
echo    terraform output argocd_admin_password
echo    terraform output grafana_admin_password
echo.
echo 💡 Keep the Command Prompt windows open for services to remain accessible
echo 💡 Close windows with Ctrl+C to stop individual services
echo.
pause
