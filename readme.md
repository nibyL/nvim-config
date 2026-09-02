# On utilise C:\Temp\ qui n'a pas d'espaces
$outputFile = "C:\Temp\neovim_config_review.txt"

# Créer le fichier vide
Set-Content -Path $outputFile -Value "" -Encoding utf8

# Parcourir tous les fichiers .lua de la config Neovim
Get-ChildItem -Path "$env:LOCALAPPDATA\nvim" -Filter *.lua -Recurse | ForEach-Object {
    $relativePath = $_.FullName.Replace("$env:LOCALAPPDATA\nvim\", "")
    
    Add-Content -Path $outputFile -Value "`n`n========================================================================" -Encoding utf8
    Add-Content -Path $outputFile -Value "FICHIER : $relativePath" -Encoding utf8
    Add-Content -Path $outputFile -Value "========================================================================`n" -Encoding utf8
    
    Get-Content -Path $_.FullName -Encoding utf8 | Add-Content -Path $outputFile -Encoding utf8
}

Write-Host "✅ Succès ! Fichier créé ici :" -ForegroundColor Green
Write-Host $outputFile -ForegroundColor Cyan