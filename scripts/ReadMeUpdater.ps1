<#

.SYNOPSIS

    Updates README.md with the current Art Institute of Chicago Image of the Day.

#>

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {

    $RepoRoot = (Get-Location).Path

}

$jsonPath = Join-Path $RepoRoot 'ArtInstituteImageOfTheDay.json'

$readmePath = Join-Path $RepoRoot 'README.md'

$art = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

$readmeContent = Get-Content -Path $readmePath -Raw

$imageSrc = "https://raw.githubusercontent.com/MarkHopper24/Art-Institute-Image-of-the-Day/refs/heads/main/$($art.LocalImage)"

$artworkSection = @"

<!-- ARTWORK_START -->

## $($art.Title)

<p align="center">

<img src="$imageSrc" width="600" height="auto"/>

</p>

**Artist:** $($art.Artist)

**Date:** $($art.DateDisplay)

**Medium:** $($art.Medium)

[View this artwork at the Art Institute of Chicago]($($art.ArtworkURL))

<!-- ARTWORK_END -->

"@

$newline = [Environment]::NewLine

$replacement = $artworkSection.TrimEnd() + $newline + $newline

$markerPattern = '(?s)<!-- ARTWORK_START -->.*?<!-- ARTWORK_END -->'

$repositoryHeadingPattern = '(?i)<h2>\s*What is this repository\?\s*</h2>'

$artworkHeadingPattern = '(?m)^## .+$'

if ([regex]::IsMatch($readmeContent, $markerPattern)) {

    $newContent = [regex]::Replace(

        $readmeContent,

        $markerPattern,

        [System.Text.RegularExpressions.MatchEvaluator] {

            param($match)

            $replacement

        },

        1

    )

}

else {

    # Legacy README support:

    # Remove everything from the first artwork heading through the repository heading.

    $artworkHeading = [regex]::Match($readmeContent, $artworkHeadingPattern)

    $repositoryHeading = [regex]::Match($readmeContent, $repositoryHeadingPattern)

    if (-not $artworkHeading.Success) {

        throw "Could not find the artwork section in README.md."

    }

    if (-not $repositoryHeading.Success) {

        throw "Could not find the 'What is this repository?' heading in README.md."

    }

    if ($artworkHeading.Index -ge $repositoryHeading.Index) {

        throw "README.md section boundaries are invalid."

    }

    $prefix = $readmeContent.Substring(0, $artworkHeading.Index).TrimEnd()

    $suffix = $readmeContent.Substring($repositoryHeading.Index)

    if ([string]::IsNullOrWhiteSpace($prefix)) {

        $newContent = $replacement + $suffix

    }

    else {

        $newContent = $prefix + $newline + $newline + $replacement + $suffix

    }

}

$newContent | Set-Content -Path $readmePath -NoNewline -Encoding UTF8

Write-Host "Updated $readmePath"