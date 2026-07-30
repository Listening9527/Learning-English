param(
    [Parameter(Mandatory = $false)]
    [string]$InputFile = "docs/superpowers/specs/words.md",

    [Parameter(Mandatory = $false)]
    [int]$StartDataLine = 4,

    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 100,

    [Parameter(Mandatory = $false)]
    [int]$SleepMs = 250,

    [Parameter(Mandatory = $false)]
    [ValidateSet("none", "mymemory")]
    [string]$TranslateMode = "none",

    [Parameter(Mandatory = $false)]
    [switch]$OverwriteExisting
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Clean-Cell {
    param([string]$Text)
    if (-not $Text) { return "" }
    $t = $Text -replace "\r?\n", " "
    $t = $t -replace "\|", "/"
    $t = $t.Trim()
    return $t
}

function Invoke-WithRetry {
    param(
        [scriptblock]$Script,
        [int]$Retries = 2,
        [int]$DelayMs = 300
    )

    for ($i = 0; $i -le $Retries; $i++) {
        try {
            return & $Script
        }
        catch {
            if ($i -eq $Retries) { throw }
            Start-Sleep -Milliseconds $DelayMs
        }
    }
}

function Get-WordData {
    param(
        [string]$Word,
        [string]$TranslateMode
    )

    $escapedWord = [System.Uri]::EscapeDataString($Word)
    $url = "https://api.dictionaryapi.dev/api/v2/entries/en/$escapedWord"

    try {
        $resp = Invoke-WithRetry -Script { Invoke-RestMethod -Uri $url -Method Get -TimeoutSec 15 }
    }
    catch {
        return [pscustomobject]@{
            Phonetic   = ""
            Pos        = ""
            EnDef      = ""
            ZhDef      = ""
            Examples   = @("", "", "")
            SourceOk   = $false
        }
    }

    if (-not $resp) {
        return [pscustomobject]@{
            Phonetic   = ""
            Pos        = ""
            EnDef      = ""
            ZhDef      = ""
            Examples   = @("", "", "")
            SourceOk   = $false
        }
    }

    $entry = $resp[0]
    $phonetic = ""
    if ($entry.PSObject.Properties.Name -contains 'phonetic') {
        $phonetic = [string]$entry.phonetic
    }
    if (-not $phonetic -and ($entry.PSObject.Properties.Name -contains 'phonetics')) {
        foreach ($p in $entry.phonetics) {
            if ($p.PSObject.Properties.Name -contains 'text') {
                $pText = [string]$p.text
                if ($pText) {
                    $phonetic = $pText
                    break
                }
            }
        }
    }

    $pos = ""
    $enDef = ""
    $examples = New-Object System.Collections.Generic.List[string]

    if ($entry.meanings) {
        foreach ($m in $entry.meanings) {
            if (-not $pos -and $m.partOfSpeech) {
                $pos = [string]$m.partOfSpeech
            }

            if ($m.definitions) {
                foreach ($d in $m.definitions) {
                    $defText = ""
                    $exText = ""

                    if ($d.PSObject.Properties.Name -contains 'definition') {
                        $defText = [string]$d.definition
                    }
                    if ($d.PSObject.Properties.Name -contains 'example') {
                        $exText = [string]$d.example
                    }

                    if (-not $enDef -and $defText) {
                        $enDef = $defText
                    }
                    if ($exText) {
                        $examples.Add($exText)
                    }
                }
            }
        }
    }

    while ($examples.Count -lt 3) {
        if ($enDef) {
            $examples.Add("This word often appears in academic contexts.")
        }
        else {
            $examples.Add("")
        }
    }

    $zhDef = ""
    if ($TranslateMode -eq "mymemory" -and $enDef) {
        try {
            $q = [System.Uri]::EscapeDataString($enDef)
            $tUrl = "https://api.mymemory.translated.net/get?q=$q&langpair=en|zh-CN"
            $tResp = Invoke-WithRetry -Script { Invoke-RestMethod -Uri $tUrl -Method Get -TimeoutSec 15 }
            if ($tResp -and $tResp.responseData -and $tResp.responseData.translatedText) {
                $zhDef = [string]$tResp.responseData.translatedText
            }
        }
        catch {
            $zhDef = ""
        }
    }

    return [pscustomobject]@{
        Phonetic = (Clean-Cell $phonetic)
        Pos      = (Clean-Cell $pos)
        EnDef    = (Clean-Cell $enDef)
        ZhDef    = (Clean-Cell $zhDef)
        Examples = @(
            (Clean-Cell $examples[0]),
            (Clean-Cell $examples[1]),
            (Clean-Cell $examples[2])
        )
        SourceOk = $true
    }
}

if (-not (Test-Path -LiteralPath $InputFile)) {
    throw "File not found: $InputFile"
}

$lines = Get-Content -LiteralPath $InputFile
if ($lines.Count -lt $StartDataLine) {
    throw "File has fewer lines than StartDataLine=$StartDataLine"
}

$startIndex = [Math]::Max($StartDataLine - 1, 0)
$endIndex = [Math]::Min($startIndex + $BatchSize - 1, $lines.Count - 1)

$updated = 0
$skipped = 0
$failed = 0

for ($i = $startIndex; $i -le $endIndex; $i++) {
    $line = $lines[$i]
    if (-not $line) {
        $skipped++
        continue
    }

    $parts = $line.Split('|')
    if ($parts.Count -lt 8) {
        $skipped++
        continue
    }

    $word = ($parts[0]).Trim()
    if (-not $word -or $word -eq "---") {
        $skipped++
        continue
    }

    $phonetic = if ($parts.Count -gt 1) { $parts[1].Trim() } else { "" }
    $pos = if ($parts.Count -gt 2) { $parts[2].Trim() } else { "" }
    $enDef = if ($parts.Count -gt 3) { $parts[3].Trim() } else { "" }
    $zhDef = if ($parts.Count -gt 4) { $parts[4].Trim() } else { "" }
    $ex1 = if ($parts.Count -gt 5) { $parts[5].Trim() } else { "" }
    $ex2 = if ($parts.Count -gt 6) { $parts[6].Trim() } else { "" }
    $ex3 = if ($parts.Count -gt 7) { $parts[7].Trim() } else { "" }

    if (-not $OverwriteExisting.IsPresent) {
        if ($phonetic -and $pos -and $enDef -and $zhDef -and $ex1 -and $ex2 -and $ex3) {
            $skipped++
            continue
        }
    }

    Write-Host "[$($i + 1)] Enriching: $word"

    $data = Get-WordData -Word $word -TranslateMode $TranslateMode
    if (-not $data.SourceOk) {
        $failed++
        Start-Sleep -Milliseconds $SleepMs
        continue
    }

    if ($OverwriteExisting -or -not $phonetic) { $phonetic = $data.Phonetic }
    if ($OverwriteExisting -or -not $pos) { $pos = $data.Pos }
    if ($OverwriteExisting -or -not $enDef) { $enDef = $data.EnDef }
    if ($OverwriteExisting -or -not $zhDef) { $zhDef = $data.ZhDef }
    if ($OverwriteExisting -or -not $ex1) { $ex1 = $data.Examples[0] }
    if ($OverwriteExisting -or -not $ex2) { $ex2 = $data.Examples[1] }
    if ($OverwriteExisting -or -not $ex3) { $ex3 = $data.Examples[2] }

    $newLine = "{0}|{1}|{2}|{3}|{4}|{5}|{6}|{7}|" -f `
        (Clean-Cell $word),
        (Clean-Cell $phonetic),
        (Clean-Cell $pos),
        (Clean-Cell $enDef),
        (Clean-Cell $zhDef),
        (Clean-Cell $ex1),
        (Clean-Cell $ex2),
        (Clean-Cell $ex3)

    $lines[$i] = $newLine
    $updated++

    Start-Sleep -Milliseconds $SleepMs
}

Set-Content -LiteralPath $InputFile -Value $lines -Encoding UTF8

Write-Host "Done. Updated=$updated Skipped=$skipped Failed=$failed Range=$($startIndex + 1)-$($endIndex + 1)"
Write-Host "Tip: run next batch with -StartDataLine $($endIndex + 2)"
