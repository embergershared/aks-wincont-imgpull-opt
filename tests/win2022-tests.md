# Performance Test for Windows Server 2019 Nodes in AKS Cluster

## Overview

## Tests

### 2019 Cold Start Test, image from ACR

This test measures the time taken to start a Windows Server 2019 pod from:

- a brand new node that never had pods (`v1.32.6, Windows Server 2022 Datacenter, 10.0.20348.4171, containerd://1.7.20+azure`),
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

### 2019 Warm Start Test, image from ACR

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

### 2022 Cold Start Test, image from MCR

1. First run

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  20s   default-scheduler  Successfully assigned win-cont-base/mcr-base-pod-22 to akswin22000002
  Normal  Pulling    18s   kubelet            Pulling image "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022"
  Normal  Pulled     11s   kubelet            Successfully pulled image "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022" in 6.754s (6.754s including waiting). Image size: 2374023537 bytes.
  Normal  Created    11s   kubelet            Created container: windows-container
  Normal  Started    3s    kubelet            Started container windows-container
```

### 2022 Warm Start Test, image from MCR

1. First run

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  8s    default-scheduler  Successfully assigned win-cont-base/mcr-base-pod-22 to akswin22000002
  Normal  Pulled     6s    kubelet            Container image "mcr.microsoft.com/dotnet/framework/runtime:4.8-windowsservercore-ltsc2022" already present on machine
  Normal  Created    6s    kubelet            Created container: windows-container
  Normal  Started    5s    kubelet            Started container windows-container
```

### 2022 Cold Start Test, image from ACR

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  114s  default-scheduler  Successfully assigned win-cont-base/acr-base-pod-22 to akswin22000004
  Normal  Pulling    112s  kubelet            Pulling image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2022:latest"
  Normal  Pulled     90s   kubelet            Successfully pulled image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2022:latest" in 22.509s (22.509s including waiting). Image size: 2374023537 bytes.
  Normal  Created    89s   kubelet            Created container: windows-container
  Normal  Started    71s   kubelet            Started container windows-container
```

### 2022 Warm Start Test, image from ACR

```bash
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  10s   default-scheduler  Successfully assigned win-cont-base/acr-base-pod-22 to akswin22000004
  Normal  Pulling    8s    kubelet            Pulling image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2022:latest"
  Normal  Pulled     8s    kubelet            Successfully pulled image "acrusw3391575s4halwincont.azurecr.io/run48-lsc2022:latest" in 320ms (320ms including waiting). Image size: 2374023537 bytes.
  Normal  Created    8s    kubelet            Created container: windows-container
  Normal  Started    6s    kubelet            Started container windows-container
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