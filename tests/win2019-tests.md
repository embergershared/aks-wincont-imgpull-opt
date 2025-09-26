# Performance Test for Windows Server 2019 Nodes in AKS Cluster

## Overview

## Tests

### Cold Start Test, image from ACR

This test measures the time taken to start a Windows Server 2019 pod from:

- a brand new node that never had pods (`v1.32.6, Windows Server 2019 Datacenter, 10.0.17763.7792, containerd://1.7.20+azure`),
- image from an ACR, same region, no specifics settings,
- image is an import of `mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019`,
- no ACR streaming,
- no Ultra SSDs on the nodes.

Results are:

1. First run

```bash
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  3m35s  default-scheduler  Successfully assigned win-cont-base/acr-base-pod-19 to akswin19000003
  Normal  Pulling    3m34s  kubelet            Pulling image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest"
  Normal  Pulled     23s    kubelet            Successfully pulled image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest" in 3m10.96s (3m10.96s including waiting). Image size: 3072610852 bytes.
  Normal  Created    23s    kubelet            Created container: windows-container
  Normal  Started    4s     kubelet            Started container windows-container

```

2. Second run

```bash
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  4m50s  default-scheduler  Successfully assigned win-cont-base/acr-base-pod-19 to akswin19000002
  Normal  Pulling    4m49s  kubelet            Pulling image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest"
  Normal  Pulled     94s    kubelet            Successfully pulled image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest" in 3m14.643s (3m14.643s including waiting). Image size: 3072610852 bytes.
  Normal  Created    94s    kubelet            Created container: windows-container
  Normal  Started    71s    kubelet            Started container windows-container
```

### Warm Start Test, image from ACR

This test measures the time taken to start a Windows Server 2019 pod from:

- a brand new node that already had the image pulled,
- image from an ACR, same region, no specifics settings,
- image is an import of `mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019`,
- no ACR streaming,
- no Ultra SSDs on the nodes.

Results are:

1. First run

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  25s   default-scheduler  Successfully assigned win-cont-base/acr-base-pod-19 to akswin19000002
  Normal  Pulling    24s   kubelet            Pulling image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest"
  Normal  Pulled     23s   kubelet            Successfully pulled image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest" in 436ms (436ms including waiting). Image size: 3072610852 bytes.
  Normal  Created    23s   kubelet            Created container: windows-container
  Normal  Started    21s   kubelet            Started container windows-container
```

2. Second run

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  20s   default-scheduler  Successfully assigned win-cont-base/acr-base-pod-19 to akswin19000002
  Normal  Pulling    19s   kubelet            Pulling image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest"
  Normal  Pulled     18s   kubelet            Successfully pulled image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2019:latest" in 343ms (343ms including waiting). Image size: 3072610852 bytes.
  Normal  Created    18s   kubelet            Created container: windows-container
  Normal  Started    16s   kubelet            Started container windows-container
```

### Cold Start Test, image from MCR

1. First run

```bash
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  7m12s  default-scheduler  Successfully assigned win-cont-base/mcr-base-pod-19 to akswin19000004
  Normal  Pulling    7m10s  kubelet            Pulling image "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019"
  Normal  Pulled     106s   kubelet            Successfully pulled image "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019" in 5m23.945s (5m23.945s including waiting). Image size: 3072610852 bytes.
  Normal  Created    106s   kubelet            Created container: windows-container
  Normal  Started    69s    kubelet            Started container windows-container
```

### Warm Start Test, image from MCR

1. First run

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  24s   default-scheduler  Successfully assigned win-cont-base/mcr-base-pod-19 to akswin19000004
  Normal  Pulled     23s   kubelet            Container image "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2019" already present on machine
  Normal  Created    23s   kubelet            Created container: windows-container
  Normal  Started    20s   kubelet            Started container windows-container

```











```powershell
# Start the timer
$startTime = Get-Date

# Create the pod
kubectl apply -f acr-base-pod-19.yaml

# Wait for the pod to be in the Running state
kubectl wait --for=condition=ready pod/acr-base-pod-19 --timeout=300s

# Stop the timer
$endTime = Get-Date

# Calculate the duration
$duration = $endTime - $startTime
Write-Host "Cold Start Test Duration: $duration"