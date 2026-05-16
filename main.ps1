# ============================================================
# Translate-Clipboard.ps1
# 改行保持対応版
# ============================================================

Add-Type -AssemblyName System.Windows.Forms

# ------ 1. クリップボード取得 ------
$original = [System.Windows.Forms.Clipboard]::GetText()

if ([string]::IsNullOrWhiteSpace($original)) {
    Write-Warning "クリップボードにテキストがありません。"
    Read-Host "Enterキーで終了"
    exit
}

Write-Host "翻訳中..." -ForegroundColor Cyan

# ------ 2. 行ごとに分割 ------
$lines = $original -split "`r?`n"

$translatedLines = @()

foreach ($line in $lines) {

    # 空行維持
    if ([string]::IsNullOrWhiteSpace($line)) {
        $translatedLines += ""
        continue
    }

    $encoded = [System.Uri]::EscapeDataString($line)

    $url = "https://translate.google.pl/m?sl=auto&tl=ja&ie=UTF-8&prev=_m&q=$encoded"

    try {

        $response = Invoke-WebRequest `
            -Uri $url `
            -Method GET `
            -UserAgent "Mozilla/5.0" `
            -UseBasicParsing

        $html = $response.Content

        if ($html -match '<div class="result-container">(.+?)</div>') {

            $translated = $matches[1]
            $translated = [System.Net.WebUtility]::HtmlDecode($translated)

            $translatedLines += $translated

        }
        else {

            $translatedLines += "[翻訳失敗]"

        }

    }
    catch {

        $translatedLines += "[通信失敗]"

    }

    # アクセス間隔を少し空ける
    Start-Sleep -Milliseconds 300
}

# ------ 3. 改行維持して結合 ------
$translatedText = $translatedLines -join "`r`n"

# ------ 4. クリップボードへ戻す ------
$result = @"
$original
──────────
Google和訳:
$translatedText
"@

[System.Windows.Forms.Clipboard]::SetText($result)

# ------ 5. 表示 ------
Write-Host ""
Write-Host "翻訳完了" -ForegroundColor Green
Write-Host $original
Write-Host "──────────"
Write-Host "Google和訳:"
Write-Host $translatedText

Read-Host "Enterキーで終了"