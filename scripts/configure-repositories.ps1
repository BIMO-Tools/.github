#Requires -Version 5.1
<#
.SYNOPSIS
    Configure public GitHub repository About fields for the BIMO-Tools organization.
.DESCRIPTION
    Sets descriptions, homepages and adds relevant topics using GitHub CLI.
    Default mode previews changes; -Apply writes them.
    Does not modify repository visibility, branches, contents, or pinned repositories.
    Requires GitHub CLI (gh) authenticated as a user with repository administration rights.
.EXAMPLE
    .\scripts\configure-repositories.ps1
.EXAMPLE
    .\scripts\configure-repositories.ps1 -Apply
#>
[CmdletBinding()]
param([switch]$Apply)

$ErrorActionPreference = 'Stop'

$repositories = @(
    @{
        Name = 'Bimo.Tools'
        Description = 'Open-source .NET SDK contracts for building custom BIMO commands for Autodesk Revit.'
        Homepage = 'https://www.nuget.org/packages/Bimo.Tools'
        Topics = @('autodesk-revit', 'revit', 'revit-api', 'bim', 'csharp', 'dotnet', 'sdk', 'automation', 'bimo')
    },
    @{
        Name = 'Revit-Python-Scripts'
        Description = 'Documented Python scripts for Revit automation, BIMO presets and AI-agent discovery.'
        Homepage = 'https://bimo.tools/docs/library/run-python'
        Topics = @('autodesk-revit', 'revit', 'revit-api', 'bim', 'python', 'ironpython', 'automation', 'mcp', 'bimo')
    },
    @{
        Name = 'RegEx'
        Description = 'Regular expression nodes for Dynamo and Autodesk Revit.'
        # Preserve the existing GitHub Pages URL.
        Homepage = $null
        Topics = @('dynamo', 'dynamo-revit', 'revit', 'regex', 'regular-expressions', 'text-processing', 'csharp')
    }
)

if ($Apply) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) is required. Install it from https://cli.github.com/.'
    }

    # Do not merge native stderr into the PowerShell pipeline: in Windows PowerShell 5.1,
    # gh auth status writes informational output to stderr, which can become a terminating error.
    & gh auth status --hostname github.com
    if ($LASTEXITCODE -ne 0) {
        throw 'Authenticate GitHub CLI first using: gh auth login'
    }
}

foreach ($repo in $repositories) {
    $fullName = "BIMO-Tools/$($repo.Name)"
    Write-Host ""
    Write-Host "$fullName" -ForegroundColor Cyan
    Write-Host "  Description: $($repo.Description)"
    if ($repo.Homepage) { Write-Host "  Website:     $($repo.Homepage)" }
    else { Write-Host '  Website:     unchanged' }
    Write-Host "  Add topics:  $($repo.Topics -join ', ')"

    if (-not $Apply) { continue }

    # gh repo edit is PowerShell-friendly: one operation with no piped JSON/UTF-8 stdin.
    # --add-topic preserves existing topics and makes repeat runs safe.
    $editArgs = @('repo', 'edit', $fullName, '--description', $repo.Description,
                  '--add-topic', ($repo.Topics -join ','))
    if ($repo.Homepage) { $editArgs += @('--homepage', $repo.Homepage) }

    & gh @editArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Repository update failed for $fullName (exit code $LASTEXITCODE). See the GitHub CLI error above."
    }
    Write-Host '  Updated successfully.' -ForegroundColor Green
}

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Preview only. Run with -Apply to update GitHub repository settings.'
}
