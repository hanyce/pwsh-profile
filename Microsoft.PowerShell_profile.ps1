# 延迟加载 posh-git 模块
# if (-not (Get-Module -Name posh-git -ErrorAction SilentlyContinue)) {
#     Import-Module posh-git
# }

# 定义 SSH 函数
function jms { ssh zhangyihan1@172.16.1.27 -p2222 }

# 延迟加载 Microsoft.WinGet.CommandNotFound 模块
if (-not (Get-Module -Name Microsoft.WinGet.CommandNotFound -ErrorAction SilentlyContinue)) {
   Import-Module -Name Microsoft.WinGet.CommandNotFound
}

# 定义 which 函数
function which ($command) { 
    Get-Command -Name $command -ErrorAction SilentlyContinue | 
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue 
}

# 设置别名
Set-Alias ll ls 
Set-Alias grep findstr
function sysinfo { Get-ComputerInfo }
function rm { Remove-Item }
function rmdir { Remove-Item -Recurse }
function cp { Copy-Item }
function mv { Move-Item }

# 设置 PSReadLine 选项
Set-PSReadLineOption -PredictionSource History 
Set-PSReadLineOption -EditMode Windows 

function env { Get-ChildItem Env: }

# 延迟加载 PSFzf 模块
if (-not (Get-Module -Name PSFzf -ErrorAction SilentlyContinue)) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
}


# Functions to mimic some of the functionality of the Unix shell
# Does the the rough equivalent of dir /s /b. For example, dirs *.png is dir /s /b *.png
function dirs {
    if ($args.Count -gt 0) {
        Get-ChildItem -Recurse -Include "$args" | Foreach-Object FullName
    } else {
        Get-ChildItem -Recurse | Foreach-Object FullName
    }
}

function sed($file, $find, $replace) {
    (Get-Content $file).replace("$find", $replace) | Set-Content $file
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function export($name, $value) {
    set-item -force -path "env:$name" -value $value;
}

function pgrep($name) {
    Get-Process $name
}

function grep {
    param (
        [string]$regex,
        [string]$dir
    )
    process {
        if ($dir) {
            Get-ChildItem -Path $dir -Recurse -File | Select-String -Pattern $regex
        } else {     # Use if piped input is provided
            $input | Select-String -Pattern $regex
        }
    }
}

function pkill {
    param (
        [string]$name
    )
    process {
        if ($name) {
            Get-Process $name -ErrorAction SilentlyContinue | Stop-Process
        } else {
            $input | ForEach-Object { Get-Process $_ -ErrorAction SilentlyContinue | Stop-Process }
        }
    }
}

function head {
    param (
        [string]$Path,
        [int]$n = 10
    )
    process {
        if ($Path) {
            Get-Content $Path -Head $n
        } else {
            $input | Select-Object -First $n
        }
    }
}

function tail {
    param (
        [string]$Path,
        [int]$n = 10
    )
    process {
        if ($Path) {
            Get-Content $Path -Tail $n
        } else {
            $input | Select-Object -Last $n
        }
    }
}

# Unzip function
function unzip {
    param (
        [string]$file
    )
    process {
        if ($file) {
            $fullPath = Join-Path -Path $pwd -ChildPath $file
            if (Test-Path $fullPath) {
                Write-Output "Extracting $file to $pwd"
                Expand-Archive -Path $fullPath -DestinationPath $pwd
            } else {
                Write-Output "File $file does not exist in the current directory"
            }
        } else {
            $input | ForEach-Object {
                $fullPath = Join-Path -Path $pwd -ChildPath $_
                if (Test-Path $fullPath) {
                    Write-Output "Extracting $_ to $pwd"
                    Expand-Archive -Path $fullPath -DestinationPath $pwd
                } else {
                    Write-Output "File $_ does not exist in the current directory"
                }
            }
        }
    }
}

function du {
    param (
        [string]$Path = (Get-Location)
    )
    try {
        # Get all items recursively at the specified path.
        $items = Get-ChildItem -Path $Path -Recurse -ErrorAction SilentlyContinue
        # Separate files and directories
        $files = $items | Where-Object { -not $_.PSIsContainer }
        $directories = $items | Where-Object { $_.PSIsContainer }
        # Measure properties
        $fileCount = $files.Count
        $directoryCount = $directories.Count
        $totalBytes = ($files | Measure-Object -Property Length -Sum).Sum
        # Convert bytes to a human-readable format
        if ($totalBytes -ge 1TB) {
            $size = "{0:N2} TB" -f ($totalBytes / 1TB)
        } elseif ($totalBytes -ge 1GB) {
            $size = "{0:N2} GB" -f ($totalBytes / 1GB)
        } elseif ($totalBytes -ge 1MB) {
            $size = "{0:N2} MB" -f ($totalBytes / 1MB)
        } elseif ($totalBytes -ge 1KB) {
            $size = "{0:N2} KB" -f ($totalBytes / 1KB)
        } else {
            $size = "{0:N2} bytes" -f $totalBytes
        }
        # Output results
        Write-Output "Directory Count : $directoryCount"
        Write-Output "File Count      : $fileCount"
        Write-Output "Total Size      : $size"
    } catch {
        Write-Output "An error occurred: $_"
    }
}

# Short ulities
function df {get-volume}

# Aliases for reboot and poweroff
function Reboot-System {Restart-Computer -Force}
Set-Alias reboot Reboot-System
function Poweroff-System {Stop-Computer -Force}
Set-Alias poweroff Poweroff-System


# Function to run a command or shell as admin.
function admin {
    if ($args.Count -gt 0) {   
        $argList = "& '" + $args + "'"
        Start-Process "wt.exe" -Verb runAs -ArgumentList $argList
    } else {
        Start-Process "wt.exe" -Verb runAs
    }
}
Set-Alias -Name sudo -Value admin

# Hash functions
function md5 {
    param (
        [string]$Path
    )
    process {
        if ($Path) {
            Get-FileHash -Algorithm MD5 $Path
        } else {
            $input | ForEach-Object { Get-FileHash -Algorithm MD5 $_ }
        }
    }
}

function sha1 {
    param (
        [string]$Path
    )
    process {
        if ($Path) {
            Get-FileHash -Algorithm SHA1 $Path
        } else {
            $input | ForEach-Object { Get-FileHash -Algorithm SHA1 $_ }
        }
    }
}

function sha256 {
    param (
        [string]$Path
    )
    process {
        if ($Path) {
            Get-FileHash -Algorithm SHA256 $Path
        } else {
            $input | ForEach-Object { Get-FileHash -Algorithm SHA256 $_ }
        }
    }
}

# Activate clash proxy policy
function proxy {
    $env:http_proxy = "http://127.0.0.1:7890"
    $env:https_proxy = "http://127.0.0.1:7890"
    $env:all_proxy = "socks5://127.0.0.1:7890"
}

# Deactivate clash proxy policy
function unproxy {
    $env:http_proxy = ""
    $env:https_proxy = ""
    $env:all_proxy = ""
}

# Show current proxy policy
function show-proxy {
    Write-Output "http_proxy: $env:http_proxy"
    Write-Output "https_proxy: $env:https_proxy"
    Write-Output "all_proxy: $env:all_proxy"
}