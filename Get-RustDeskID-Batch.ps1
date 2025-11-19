# Get-RustDeskID-Batch.ps1
# 批量获取多台计算机的 RustDesk ID

param(
    [string]$ComputerListFile = "",  # 计算机列表文件（每行一个计算机名）
    [string[]]$ComputerNames = @(),  # 或直接指定计算机名数组
    [string]$OutputFile = "RustDesk_IDs_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    [string]$ConfigPath = "RustDesk\config\RustDesk.toml"
)

Write-Host "=== RustDesk ID 批量查询 ===" -ForegroundColor Cyan
Write-Host ""

# 获取计算机列表
$computers = @()
if ($ComputerListFile -and (Test-Path $ComputerListFile)) {
    $computers = Get-Content $ComputerListFile | Where-Object { $_.Trim() -ne "" }
    Write-Host "✅ 从文件读取 $($computers.Count) 台计算机" -ForegroundColor Green
    Write-Host "文件: $ComputerListFile" -ForegroundColor Gray
} elseif ($ComputerNames.Count -gt 0) {
    $computers = $ComputerNames
    Write-Host "✅ 指定 $($computers.Count) 台计算机" -ForegroundColor Green
} else {
    # 默认只查询本机
    $computers = @($env:COMPUTERNAME)
    Write-Host "⚠️ 未指定计算机列表，仅查询本机" -ForegroundColor Yellow
}

Write-Host ""

# 结果数组
$results = @()
$successCount = 0
$failCount = 0

foreach ($computer in $computers) {
    $computer = $computer.Trim()
    Write-Host "[$computer] 正在查询..." -ForegroundColor Yellow
    
    try {
        # 构建远程配置文件路径
        $remoteConfigPath = "\\$computer\C$\Users\*\AppData\Roaming\$ConfigPath"
        
        # 查找配置文件
        $configFiles = Get-ChildItem $remoteConfigPath -ErrorAction Stop
        
        if ($configFiles.Count -eq 0) {
            Write-Host "[$computer] ❌ 未找到配置文件" -ForegroundColor Red
            $results += [PSCustomObject]@{
                ComputerName = $computer
                RustDeskID = "NOT_FOUND"
                Status = "配置文件不存在"
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
            $failCount++
            continue
        }
        
        # 读取第一个找到的配置文件
        $configFile = $configFiles[0]
        $config = Get-Content $configFile.FullName -Raw
        
        # 提取 ID
        $id = $null
        if ($config -match 'id\s*=\s*"([^"]+)"') {
            $id = $matches[1]
        } elseif ($config -match "id\s*=\s*'([^']+)'") {
            $id = $matches[1]
        } elseif ($config -match 'id\s*=\s*([^\s]+)') {
            $id = $matches[1]
        }
        
        if ($id) {
            Write-Host "[$computer] ✅ ID: $id" -ForegroundColor Green
            $results += [PSCustomObject]@{
                ComputerName = $computer
                RustDeskID = $id
                Status = "成功"
                ConfigPath = $configFile.FullName
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
            $successCount++
        } else {
            Write-Host "[$computer] ⚠️ 无法提取 ID" -ForegroundColor Yellow
            $results += [PSCustomObject]@{
                ComputerName = $computer
                RustDeskID = "PARSE_ERROR"
                Status = "无法解析配置文件"
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
            $failCount++
        }
    } catch {
        Write-Host "[$computer] ❌ 访问失败: $($_.Exception.Message)" -ForegroundColor Red
        $results += [PSCustomObject]@{
            ComputerName = $computer
            RustDeskID = "ERROR"
            Status = "访问失败: $($_.Exception.Message)"
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
        $failCount++
    }
}

Write-Host ""
Write-Host "=== 查询完成 ===" -ForegroundColor Cyan
Write-Host "总计: $($computers.Count) 台" -ForegroundColor White
Write-Host "成功: $successCount 台" -ForegroundColor Green
Write-Host "失败: $failCount 台" -ForegroundColor Red
Write-Host ""

# 导出结果
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
    Write-Host "✅ 结果已导出到: $OutputFile" -ForegroundColor Green
    Write-Host ""
    
    # 显示结果表格
    Write-Host "查询结果：" -ForegroundColor Yellow
    $results | Format-Table -AutoSize
    
    # 显示成功的 ID 列表
    $successResults = $results | Where-Object { $_.Status -eq "成功" }
    if ($successResults.Count -gt 0) {
        Write-Host ""
        Write-Host "=== 可用的 RustDesk ID ===" -ForegroundColor Green
        foreach ($result in $successResults) {
            Write-Host "  $($result.ComputerName): $($result.RustDeskID)" -ForegroundColor Cyan
        }
    }
} else {
    Write-Host "⚠️ 没有任何结果" -ForegroundColor Yellow
}
