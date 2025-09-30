# Windows Container Image Pull Optimization Test Plan

## Test Parameters Matrix

### Variables

1. Base Windows Images:
   - Windows Server 2019
   - Windows Server 2022

2. Image Source:
   - Microsoft Container Registry (MCR)
   - Azure Container Registry (ACR)

3. Node Storage:
   - Standard SSD
   - Ultra SSD

4. ACR Features:
   - Standard (ACR streaming OFF)
   - ACR streaming ON (only applicable for ACR source)
   - Only for Linux AMD x64 nodes => not an option for Windows nodes

## Test Combinations Matrix

| Test ID | Base Image | Image Source | Node Storage | .NET Framework | Duration (s) | Notes |
|---------|------------|--------------|--------------|----------------|--------------|-------|

# .NET Framework 3.5

| T1      | Win2019    | MCR          | Standard     | 3.5            |     309      |       |
| T2      | Win2022    | MCR          | Standard     | 3.5            |     140      |   54% faster than 2019    |

| T3      | Win2019    | ACR          | Standard     | 3.5            |     301      |       |
| T4      | Win2022    | ACR          | Standard     | 3.5            |     249      |   17% faster than 2019    |

| T12     | Win2019    | ACR          | Ultra SSDs   | 3.5            |              |       |
| T12     | Win2022    | ACR          | Ultra SSDs   | 3.5            |              |       |

# .NET Framework 4.8

| T5      | Win2019    | MCR          | Standard     | 4.8            |      363     |       |
| T6      | Win2022    | MCR          | Standard     | 4.8            |       17     |   95% faster than 2019    |

| T5      | Win2019    | ACR          | Standard     | 4.8            |      362     |       |
| T6      | Win2022    | ACR          | Standard     | 4.8            |       22     |   94% faster than 2019    |


## Test Procedure

For each test combination:

1. **Pre-requisites**:
   - Ensure a fresh AKS cluster with the specified node configuration
   - Verify no previous deployments of the test images
   - Clear local image cache if any exists
   - Record cluster state and node resources

2. **Test Steps**:
   - Record start time
   - Deploy pod using the appropriate YAML configuration
   - Monitor pod status until Running
   - Record end time when pod reaches Running state
   - Calculate total duration

3. **Data Collection**:
   - Pod creation duration (seconds)
   - Node resource utilization during pull
   - Network metrics if available
   - Any errors or warnings

## Results Analysis Template

### Summary Table by Base Image

| Base Image | Fastest Configuration | Duration (sec) |
|------------|---------------------|----------------|
| Win2019    |                     |                |
| Win2022    |                     |                |

### Summary Table by Image Source

| Image Source | Fastest Configuration | Duration (sec) |
|-------------|---------------------|----------------|
| MCR         |                     |                |
| ACR         |                     |                |

### Performance Impact Analysis

1. **Storage Impact**:
   - Ultra SSD vs Standard SSD performance difference
   - Cost-benefit analysis

2. **ACR Streaming Impact**:
   - Performance improvement percentage
   - Scenarios where it's most effective

3. **Image Source Impact**:
   - MCR vs ACR performance comparison
   - Regional impact considerations

## Test Environment Details

- AKS Version:
- Region:
- Network Plugin:
- Node Size:
- Container Runtime Version:

## Recommendations

(To be filled after test completion)

1. Fastest overall combination:
2. Most cost-effective combination:
3. Best practice recommendations:

## Notes

- All tests should be run at least 3 times to get average values
- Tests should be run during similar time periods to minimize external factors
- Document any anomalies or external factors that might affect results