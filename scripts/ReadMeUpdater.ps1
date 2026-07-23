<#
.SYNOPSIS
    Updates README.md with the current Art Institute of Chicago Image of the Day.

.DESCRIPTION
    Reads ArtInstituteImageOfTheDay.json and rewrites the artwork section of README.md
    (between the header image and the "What is this repository?" heading) with the current
    artwork's title, image, artist, date, medium, and a link to the artwork page.

.NOTES
    File Name      : ReadMeUpdater.ps1
    Author         : Mark Hopper
    Prerequisite   : ArtInstituteImageOfTheDay.json and README.md must exist in the parent directory.

.EXAMPLE
    .\ReadMeUpdater.ps1
#>

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }

$jsonPath = Join-Path $RepoRoot "ArtInstituteImageOfTheDay.json"
$readmePath = Join-Path $RepoRoot "README.md"

$art = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
$readmeContent = Get-Content -Path $readmePath -Raw

$imageSrc = "https://raw.githubusercontent.com/MarkHopper24/Art-Institute-Image-of-the-Day/refs/heads/main/$($art.LocalImage)"

# Build the artwork section that sits between the header and "What is this repository?".
$artworkSection = @"
## $($art.Title)
<p align="center">
<img src="$imageSrc" width="600" height="auto"/>
</p>

**Artist:** $($art.Artist)

**Date:** $($art.DateDisplay)

**Medium:** $($art.Medium)

[View this artwork at the Art Institute of Chicago]($($art.ArtworkURL))
"@

# Replace everything between the closing </p> of the header block and the
# "What is this repository?" heading.
$pattern = "(?s)(?<=<\/p>\r?\n\r?\n).*?(?=<h2>What is this repository\?)"
$newContent = $readmeContent -replace $pattern, "$artworkSection`n`n"

$newContent | Set-Content -Path $readmePath -NoNewline -Encoding UTF8
Write-Host "Updated $readmePath"
