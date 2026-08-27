$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$packageDirectory = Join-Path $repoRoot 'Tweaks'
$packagesPath = Join-Path $repoRoot 'Packages'
$packagesGzipPath = Join-Path $repoRoot 'Packages.gz'

$entries = foreach ($packagePath in Get-ChildItem -Path $packageDirectory -Filter '*.deb' -File | Sort-Object Name) {
    $fileHash = (Get-FileHash -Path $packagePath.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    $packageName = $packagePath.BaseName -replace '_[^_]+_iphoneos-(?:arm64e|arm64)$', ''
    $versionMatch = [regex]::Match($packagePath.Name, '^.+_(?<version>[^_]+)_iphoneos-(?<architecture>[^.]+)\.deb$')

    if (-not $versionMatch.Success) {
        throw "Package filename does not match the expected format: $($packagePath.Name)"
    }

    @(
        "Package: $packageName"
        "Version: $($versionMatch.Groups['version'].Value)"
        "Architecture: iphoneos-$($versionMatch.Groups['architecture'].Value)"
        "Filename: ./Tweaks/$($packagePath.Name)"
        "Size: $($packagePath.Length)"
        "SHA256: $fileHash"
        "Description: $packageName jailbreak tweak"
        "Section: Tweaks"
        ''
    ) -join "`n"
}

[IO.File]::WriteAllText($packagesPath, (($entries -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))

$inputStream = [IO.File]::OpenRead($packagesPath)
$outputStream = [IO.File]::Create($packagesGzipPath)
$gzipStream = [IO.Compression.GZipStream]::new($outputStream, [IO.Compression.CompressionMode]::Compress)
try {
    $inputStream.CopyTo($gzipStream)
} finally {
    $gzipStream.Dispose()
    $inputStream.Dispose()
    $outputStream.Dispose()
}

Write-Host "Indexed $($entries.Count) package(s)."