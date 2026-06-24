# Virus Detector — 扩展打包脚本 (PowerShell)
# 用法: .\scripts\package.ps1 [[-Output] <路径>]
# 默认输出: _dist/VirusDetector.zip

param(
  [string]$Output = ""
)

$ProjectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if (-not $Output) {
  $Output = Join-Path $ProjectDir "_dist\VirusDetector.zip"
}

# 确保输出目录存在
$OutputDir = Split-Path $Output -Parent
if (-not (Test-Path $OutputDir)) { New-Item -ItemType Directory -Force $OutputDir | Out-Null }

# 需打包的文件列表 (相对于项目根目录)
$Include = @(
  "manifest.json"
  "LICENSE"
  "icons/icon16.png"
  "icons/icon32.png"
  "icons/icon48.png"
  "icons/icon128.png"
  "background/cache-manager.js"
  "background/domain-database.js"
  "background/icp-utils.js"
  "background/rdap-client.js"
  "background/scoring-engine.js"
  "background/service-worker.js"
  "background/similarity.js"
  "background/whois-client.js"
  "content/content-script.js"
  "popup/popup.html"
  "popup/popup.css"
  "popup/popup.js"
  "warning/warning.html"
  "warning/warning.css"
  "warning/warning.js"
  "utils/constants.js"
  "utils/messaging.js"
  "utils/trusted-platforms.js"
  "utils/url-utils.js"
)

# 使用临时文件避免 .NET ZipFile::Open(Create) 无法覆盖已存在文件的问题
$tmpFile = [System.IO.Path]::GetTempFileName()
Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue  # GetTempFileName 会创建空文件，需先删掉
try {
  Add-Type -AssemblyName System.IO.Compression.FileSystem -ErrorAction Stop

  $zip = [System.IO.Compression.ZipFile]::Open($tmpFile, [System.IO.Compression.ZipArchiveMode]::Create)
  try {
    foreach ($relPath in $Include) {
      $fullPath = Join-Path $ProjectDir $relPath.Replace("/", "\")
      if (Test-Path $fullPath) {
        $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
          $zip, $fullPath, $relPath,
          [System.IO.Compression.CompressionLevel]::Optimal
        )
      } else {
        Write-Warning "文件不存在，跳过: $relPath"
      }
    }
  } finally {
    $zip.Dispose()
  }

  # 覆盖目标文件
  Move-Item -Path $tmpFile -Destination $Output -Force -ErrorAction Stop

  # 验证
  $reader = [System.IO.Compression.ZipFile]::OpenRead($Output)
  $count = $reader.Entries.Count
  $reader.Dispose()

  $size = (Get-ChildItem $Output).Length / 1KB
  Write-Output "✅ 打包完成: $([math]::Round($size)) KB — $Output"
  Write-Output "   文件数: $count"

} catch {
  Write-Error "❌ 打包失败: $_"
  # 清理临时文件
  if (Test-Path $tmpFile) { Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue }
  exit 1
}
