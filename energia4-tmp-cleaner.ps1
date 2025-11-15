#Requires -RunAsAdministrator

$targetPath = "Documents\Energia4\tmp\E4Updater"

$userFolders = Get-ChildItem -Path "C:\Users" -Directory | 
    Where-Object { $_.Name -notmatch '^(Public|Default|Default User|All Users)$' }

foreach ($userFolder in $userFolders) {
    $fullPath = Join-Path $userFolder.FullName $targetPath
    
    if (Test-Path $fullPath) {
        try {
            # Próba hurtowego usunięcia
            Get-ChildItem -Path $fullPath -Recurse -Force -ErrorAction Stop | 
                Remove-Item -Recurse -Force -ErrorAction Stop
        }
        catch {
            # Fallback - usuwaj pojedynczo jeśli hurtowe nie działa
            Get-ChildItem -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue | 
                ForEach-Object {
                    try {
                        Remove-Item $_.FullName -Force -Recurse -ErrorAction Stop
                    }
                    catch {
                        # Plik zablokowany - skipujemy
                    }
                }
        }
    }
}
