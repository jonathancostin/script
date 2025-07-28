# ~/.config/powershell/Microsoft.PowerShell_profile.ps1

# 3. oh-my-posh binary via Homebrew
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue))
{
  if (Get-Command brew -ErrorAction SilentlyContinue)
  {
    Write-Host 'Installing oh-my-posh via Homebrew…' -ForegroundColor Yellow
    brew install jandedobbeleer/oh-my-posh/oh-my-posh
  } else
  {
    Write-Warning 'Homebrew not found. Please install Oh-My-Posh manually.'
  }
}

# 4. Theme cache in XDG_CONFIG_HOME or ~/.config
$xdg       = if ($env:XDG_CONFIG_HOME)
{ $env:XDG_CONFIG_HOME 
} else
{ "$HOME/.config" 
}
$themeDir  = Join-Path $xdg 'oh-my-posh/themes'
$themeFile = Join-Path $themeDir 'bubbles.omp.json'
$themeName = 'bubbles'

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue)
{

  # Download the theme only once
  if (-not (Test-Path $themeFile -PathType Leaf))
  {
    New-Item -ItemType Directory -Path $themeDir -Force | Out-Null
    Write-Host "Downloading $themeName theme…" -ForegroundColor Yellow

    # capture the JSON emitted by the CLI
    $json = & oh-my-posh get theme $themeName 2>$null
    if ($LASTEXITCODE -eq 0 -and $json)
    {
      # write it out as UTF-8
      $json | Set-Content -Path $themeFile -Encoding UTF8
    } else
    {
      Write-Warning "Failed to fetch theme '$themeName'"
    }
  }

  # initialize the prompt with the cached file
  oh-my-posh init pwsh --config $themeFile | Invoke-Expression
} else
{
  Write-Warning 'oh-my-posh not found, skipping theme init.'
}

# 5. PSReadLine tweaks
Import-Module PSReadLine
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Vi
Set-PSReadLineOption -Colors @{
  Command   = 'Cyan'
  Parameter = 'Yellow'
  String    = 'Green'
  Comment   = 'DarkGray'
  Number    = 'Magenta'
  Operator  = 'White'
  Type      = 'DarkYellow'
}

# 6. Env vars & PATH
$env:EDITOR = 'nvim'
$env:VISUAL = 'nvim'
# 7. Aliases (force overwrite)
Set-Alias ll  Get-ChildItem               -Force
Set-Alias la  'Get-ChildItem -Force'      -Force
Set-Alias gst 'git status'                -Force
Set-Alias gl  'git log --oneline --graph' -Force
Set-Alias ..  'Set-Location ..'           -Force
Set-Alias ... 'Set-Location ../..'        -Force

# 10. Final touches
Write-Host '💸 PowerShell profile loaded 💸' -ForegroundColor Cyan


