<#
.SYNOPSIS
  Disable Windows visual effects for maximum performance
#>

Write-Host "==> Disabling transparency, animations, and extra visual effects..."

# Disable transparency and animations
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f

# Disable visual fluff via performance options
$perf = 'HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects'
reg add $perf /v VisualFXSetting /t REG_DWORD /d 2 /f   # 2 = Adjust for best performance

# Disable Widgets and News
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Feeds" /v ShellFeedsTaskbarViewMode /t REG_DWORD /d 2 /f
Get-AppxPackage *WebExperience* | Remove-AppxPackage -ErrorAction SilentlyContinue

Write-Host "✅ Visual effects trimmed for maximum performance."
