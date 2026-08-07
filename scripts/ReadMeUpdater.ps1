<#

.SYNOPSIS

    Updates README.md with the current Art Institute of Chicago Image of the Day.

.DESCRIPTION

    Reads ArtInstituteImageOfTheDay.json and replaces the README artwork section.

    The README image uses the current Art Institute IIIF URL instead of the local

    artwork.jpg file, which may be stale or cached.

#>

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {

    $RepoRoot = (Get-Location).Path

}

$jsonPath = Join-Path $RepoRoot 'ArtInstituteImageOfTheDay.json'

$readmePath = Join-Path $RepoRoot 'README.md'

if (-not (Test-Path $jsonPath)) {

    throw "JSON file not found: $jsonPath"

}

if (-not (Test-Path $readmePath)) {

    throw "README file not found: $readmePath"

}

$art = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json

$readmeContent = Get-Content -Path $readmePath -Raw

$imageSrc = $art.ImageURLLarge

if ([string]::IsNullOrWhiteSpace($imageSrc)) {

    $imageSrc = $art.ImageURL

}

if ([string]::IsNullOrWhiteSpace($imageSrc)) {

    throw 'No artwork image URL was found in ArtInstituteImageOfTheDay.json.'

}

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

    $artworkHeading = [regex]::Match(

        $readmeContent,

        $artworkHeadingPattern

    )

    $repositoryHeading = [regex]::Match(

        $readmeContent,

        $repositoryHeadingPattern

    )

    if (-not $artworkHeading.Success) {

        throw 'Could not find the artwork section in README.md.'

    }

    if (-not $repositoryHeading.Success) {

        throw "Could not find the 'What is this repository?' heading in README.md."

    }

    if ($artworkHeading.Index -ge $repositoryHeading.Index) {

        throw 'README section boundaries are invalid.'

    }

    $prefix = $readmeContent.Substring(

        0,

        $artworkHeading.Index

    ).TrimEnd()

    $suffix = $readmeContent.Substring(

        $repositoryHeading.Index

    )

    if ([string]::IsNullOrWhiteSpace($prefix)) {

        $newContent = $replacement + $suffix

    }

    else {

        $newContent =

            $prefix +

            $newline +

            $newline +

            $replacement +

            $suffix

    }

}

    Set-Content -Path $readmePath -Value $newContent -NoNewline -Encoding UTF8

Write-Host "Updated $readmePath"