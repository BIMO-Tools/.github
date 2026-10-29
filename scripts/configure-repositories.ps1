#Requires -Version 5.1
<#
.SYNOPSIS
    Configure public GitHub repository About fields for the BIMO-Tools organization.
.DESCRIPTION
    Applies descriptions, homepages and topics. Preview is the default.
    Does not alter visibility, branches, repository contents or pinned repositories.
    Requires GitHub CLI (gh) authenticated as an organization owner/repository admin.
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
        # Keep the existing GitHub Pages URL; do not overwrite it.
        Homepage = $null
        Topics = @('dynamo', 'dynamo-revit', 'revit', 'regex', 'regular-expressions', 'text-processing', 'csharp')
    }
)

if ($Apply) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw 'GitHub CLI (gh) is required. Install it from https://cli.github.com/.'
    }

    & gh auth status --hostname github.com 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw 'Authenticate GitHub CLI first using: gh auth login'
    }
}

foreach ($repo in $repositories) {
    $fullName = "BIMO-Tools/$($repo.Name)"
    Write-Host "$fullName" -ForegroundColor Cyan
    Write-Host "  Description: $($repo.Description)"
    if ($repo.Homepage) { Write-Host "  Website:     $($repo.Homepage)" }
    else { Write-Host '  Website:     unchanged' }
    Write-Host "  Topics:      $($repo.Topics -join ', ')"

    if (-not $Apply) { continue }

    $patchArgs = @('--method', 'PATCH', "repos/$fullName", '--field', "description=$($repo.Description)", '--silent')
    if ($repo.Homepage) { $patchArgs += @('--field', "homepage=$($repo.Homepage)") }

    & gh api @patchArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to update About metadata for $fullName."
    }

    $topicsJson = @{ names = @($repo.Topics) } | ConvertTo-Json -Depth 3 -Compress
    $topicsJson | & gh api --method PUT "repos/$fullName/topics" --header 'Accept: application/vnd.github+json' --input - --silent
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to update topics for $fullName."
    }
    Write-Host '  Updated.' -ForegroundColor Green
}

if (-not $Apply) {
    Write-Host ''
    Write-Host 'Preview only. Run the script with -Apply to update GitHub repository settings.'
}
