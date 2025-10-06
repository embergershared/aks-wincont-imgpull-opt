# Windows Container Image Pull Optimization Test Plan

## Test Parameters Matrix

### Variables

1. Base Windows Images:
   - Windows Server 2019
   - Windows Server 2022

2. Cold vs. Warm pods creation:
   - Cold: No prior image on node
   - Warm: Image already present on node

3. .Net Framework Versions:
   - .NET Framework 3.5
   - .NET Framework 4.8

4. Image Source:
   - Microsoft Container Registry (MCR)
   - Azure Container Registry (ACR)

5. ACR Features:
   - Standard (ACR streaming OFF)
   - ACR streaming ON (only applicable for ACR source)
   - Only for Linux AMD x64 nodes => not an option for Windows nodes

## Test Combinations Matrix

# .NET Framework 3.5

| Test ID | Base Image | Image Source | Pod creation | .NET Framework | Duration (s) | Notes |
|---------|------------|--------------|--------------|----------------|--------------|-------|
| T1      | Win2019    | MCR          | Cold     | 3.5            |     309      |       |
| T2      | Win2022    | MCR          | Cold     | 3.5            |     140      |   54% faster than 2019    |
| T3      | Win2019    | MCR          | Warm     | 3.5            |      4     |       |
| T4      | Win2022    | MCR          | Warm     | 3.5            |      3     |       |
| T5      | Win2019    | ACR          | Cold     | 3.5            |     301      |       |
| T6      | Win2022    | ACR          | Cold     | 3.5            |     249      |   17% faster than 2019    |
| T7      | Win2019    | ACR          | Warm     | 3.5            |      4s     |       |
| T8      | Win2022    | ACR          | Warm     | 3.5            |      3s    |       |

# .NET Framework 4.8

| Test ID | Base Image | Image Source | Pod creation | .NET Framework | Duration (s) | Notes |
|---------|------------|--------------|--------------|----------------|--------------|-------|
| T9       | Win2019    | MCR          | Cold     | 4.8            |      363     |       |
| T10      | Win2022    | MCR          | Cold     | 4.8            |       17     |   95% faster than 2019    |
| T11      | Win2019    | MCR          | Warm     | 4.8            |           |       |
| T12      | Win2022    | MCR          | Warm     | 4.8            |           |     |
| T13      | Win2019    | ACR          | Cold     | 4.8            |      362     |       |
| T14      | Win2022    | ACR          | Cold     | 4.8            |       22     |   94% faster than 2019    |
| T15      | Win2019    | ACR          | Warm     | 4.8            |           |       |
| T16      | Win2022    | ACR          | Warm     | 4.8            |           |     |

## Pull the image manually on a node

```powershell
kubectl apply -f host-process-2019.yaml
kubectl exec hpc-2019 -- powershell "crictl pull acrusw3391575s4halwincont.azurecr.io/run35-svrcore-ltsc2019:latest"
```
