# Sinkronkan sumber Flutter yang sudah dilacak, setelah perubahan stabil.
$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
$previous = ''
while ($true) {
    if ((git branch --show-current) -ne 'main') { throw 'Gunakan branch main.' }
    $changes = (git diff -- lib pubspec.yaml pubspec.lock) -join "`n"
    if ($changes -and $changes -eq $previous) {
        git diff --cached --quiet
        if ($LASTEXITCODE -ne 0) { throw 'Selesaikan perubahan staged terlebih dahulu.' }
        git add -u -- lib pubspec.yaml pubspec.lock
        if ($LASTEXITCODE -ne 0) { throw 'Git add gagal.' }
        git commit -m 'Perbarui sumber aplikasi ongkir'
        if ($LASTEXITCODE -ne 0) { throw 'Commit gagal.' }
        git push origin main
        if ($LASTEXITCODE -ne 0) { throw 'Push gagal. Periksa git status.' }
    }
    $previous = $changes
    Start-Sleep -Seconds 10
}
