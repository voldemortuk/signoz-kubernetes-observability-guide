# Troubleshooting Guide

This document provides solutions to common issues you might encounter while setting up SigNoz with Kubernetes observability.

## Common Issues and Solutions

### 1. Helm Installation Conflicts

**Error:** `cannot re-use a name that is still in use`

**Solution:**
```bash
# Check existing releases
helm list -n signoz

# Uninstall failed release
helm uninstall <release-name> -n signoz

# Reinstall with correct configuration
helm install <release-name> signoz/k8s-infra -f override-values.yaml -n signoz
```

### 2. Volume Mount Conflicts

**Error:** `Duplicate value: "varlog"` or `must be unique`

**Solution:**
This occurs when trying to add custom volume mounts that conflict with built-in ones. Use the simplified configuration in `override-values.yaml` without custom `extraVolumes` or `extraVolumeMounts`.

### 3. Missing SigNoz Ingestion Key

**Error:** Configuration not working or logs not appearing in SigNoz Cloud

**Solution:**
1. Ensure you have the correct SigNoz ingestion key from your SigNoz Cloud account
2. Update the `signozApiKey` field in `override-values.yaml`
3. Verify the correct region endpoint (`us`, `in`, or `eu`)

### 4. Pods Not Starting

**Problem:** Pods stuck in `Pending` or `CrashLoopBackOff` state

**Diagnosis:**
```bash
# Check pod status
kubectl get pods -n signoz

# Check pod logs
kubectl logs <pod-name> -n signoz

# Describe pod for events
kubectl describe pod <pod-name> -n signoz
```

**Common Solutions:**
- Ensure Docker Desktop has enough memory allocated (at least 4GB)
- Check if the cluster has sufficient resources
- Verify network connectivity

### 5. Kind Cluster Issues

**Problem:** Kind cluster not accessible or `kubectl` commands failing

**Solution:**
```bash
# Check if cluster exists
kind get clusters

# Delete and recreate cluster
kind delete cluster --name signoz-cluster
kind create cluster --name signoz-cluster

# Verify kubectl context
kubectl config current-context
```

### 6. No Logs Appearing in SigNoz Cloud

**Diagnosis Steps:**
1. **Check if k8s-infra is running:**
   ```bash
   kubectl get daemonsets -n signoz
   kubectl get pods -n signoz | grep k8s-infra
   ```

2. **Check otel-agent logs:**
   ```bash
   kubectl logs daemonset/k8s-infra-otel-agent -n signoz
   ```

3. **Verify configuration:**
   ```bash
   kubectl get configmap -n signoz
   kubectl describe configmap <k8s-infra-configmap> -n signoz
   ```

**Common Solutions:**
- Verify the SigNoz ingestion key is correct
- Check if the region endpoint matches your SigNoz Cloud region
- Ensure `presets.otlpExporter.enabled: true` in configuration
- Wait 2-3 minutes for logs to appear (there can be a delay)

### 7. Docker Desktop Memory Issues

**Problem:** Containers failing due to insufficient memory

**Solution:**
1. Open Docker Desktop
2. Go to Settings > Resources > Advanced
3. Increase memory allocation to at least 4GB
4. Restart Docker Desktop
5. Recreate the Kind cluster

### 8. Network Connectivity Issues

**Problem:** Cannot reach SigNoz Cloud endpoint

**Diagnosis:**
```bash
# Test connectivity from within a pod
kubectl run test-pod --image=busybox --rm -it -- /bin/sh
# Inside the pod:
nslookup ingest.in.signoz.cloud
wget -O- https://ingest.in.signoz.cloud:443
```

**Solutions:**
- Check corporate firewall settings
- Verify DNS resolution
- Ensure outbound HTTPS traffic is allowed

### 9. Helm Repository Issues

**Problem:** Cannot add or update SigNoz Helm repository

**Solution:**
```bash
# Force update repository
helm repo add signoz https://charts.signoz.io --force-update
helm repo update

# If still failing, remove and re-add
helm repo remove signoz
helm repo add signoz https://charts.signoz.io
helm repo update
```

### 10. Configuration Validation

**Problem:** Unsure if configuration is correct

**Validation Checklist:**
- [ ] `signozApiKey` is set to your actual ingestion key (not placeholder)
- [ ] `otelCollectorEndpoint` uses the correct region (`us`, `in`, or `eu`)
- [ ] `clusterName` is set to a meaningful name
- [ ] `deploymentEnvironment` is set appropriately
- [ ] No custom `extraVolumes` or `extraVolumeMounts` in the configuration

## Useful Commands for Debugging

### General Kubernetes Commands
```bash
# Get all resources in signoz namespace
kubectl get all -n signoz

# Check events in namespace
kubectl get events -n signoz --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n signoz
kubectl top nodes
```

### Helm Commands
```bash
# List all releases
helm list -A

# Get release history
helm history <release-name> -n signoz

# Rollback to previous version
helm rollback <release-name> -n signoz
```

### Log Analysis
```bash
# Follow logs in real-time
kubectl logs -f deployment/<deployment-name> -n signoz

# Get logs from all containers in a pod
kubectl logs <pod-name> -n signoz --all-containers=true

# Get previous logs (if pod restarted)
kubectl logs <pod-name> -n signoz --previous
```

## Getting Help

If you're still experiencing issues:

1. **Check the logs** using the commands above
2. **Search the SigNoz Community** at https://community.signoz.io/
3. **Review SigNoz Documentation** at https://signoz.io/docs/
4. **Create an issue** in this repository with:
   - Your operating system
   - Output of `kubectl get pods -n signoz`
   - Relevant error logs
   - Your configuration file (with sensitive data removed)

## Prevention Tips

1. **Resource Management:** Ensure your system has adequate resources before starting
2. **Clean Environment:** Start with a fresh Kind cluster for testing
3. **Incremental Deployment:** Deploy components step by step to isolate issues
4. **Configuration Validation:** Double-check configuration files before deployment
5. **Documentation:** Keep track of what you've modified for easier debugging
