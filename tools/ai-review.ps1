<#
.SYNOPSIS
  AI review of a kicad-happy report using a LOCAL CLI login (Claude Code or Codex/ChatGPT).
  No API key / API billing: uses whichever account the CLI is logged in with.

.EXAMPLE
  .\tools\ai-review.ps1 -PrNumber 7 -Post
  .\tools\ai-review.ps1 -Provider codex -ReportPath .\report.md
#>
param(
  [ValidateSet('claude', 'codex')][string]$Provider = 'claude',
  [string]$ReportPath,
  [int]$PrNumber,
  [switch]$Post,
  [string]$Repo = $env:GITHUB_REPOSITORY
)
$ErrorActionPreference = 'Stop'
if (-not $Repo) { $Repo = 'MadManUAV/L431_RC_Periph' }

if (-not $ReportPath) {
  if (-not $PrNumber) { throw 'Give -ReportPath or -PrNumber' }
  $sha = gh pr view $PrNumber --repo $Repo --json headRefOid --jq .headRefOid
  $runId = gh run list --repo $Repo --workflow kicad-happy.yml --commit $sha --status success -L 1 --json databaseId --jq '.[0].databaseId'
  if (-not $runId) { throw "No successful kicad-happy analysis run for $sha yet" }
  $tmp = Join-Path ([IO.Path]::GetTempPath()) "kicad-review-$runId"
  if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
  gh run download $runId --repo $Repo --name kicad-review --dir $tmp
  $ReportPath = Join-Path $tmp 'report.md'
}

$report = (Get-Content $ReportPath -Raw)
if ($report.Length -gt 12000) { $report = $report.Substring(0, 12000) }
$prompt = @"
Review this deterministic KiCad analysis report (from kicad-happy) for an STM32L431 CAN/RC peripheral board.
Do not just restate it. Instead:
1. Say which WARNING/CRITICAL findings look genuine vs likely false positives, and why.
2. Flag design concerns the report may have missed (power, protection, CAN, decoupling).
3. Give a short prioritized action list.
Reply in concise markdown, under 2000 characters. Do not use tools or read files.

----- REPORT -----
$report
"@

# Prompt goes via stdin so report content is never parsed as CLI arguments.
if ($Provider -eq 'claude') {
  $review = $prompt | claude -p --output-format text "--tools="
} else {
  $review = $prompt | codex exec --sandbox read-only --skip-git-repo-check -
}
if ($LASTEXITCODE -ne 0 -or -not $review) { throw "$Provider review failed (exit $LASTEXITCODE). Is the CLI logged in?" }
$review = ($review -join "`n")

$marker = '<!-- kicad-ai-review -->'
$name = if ($Provider -eq 'claude') { 'Claude' } else { 'ChatGPT' }
$body = "$marker`n## AI Design Review ($name, local)`n`n$review`n`n<sub>Generated locally from the kicad-happy report; verify against datasheets.</sub>`n"

if (-not $Post) { $body; return }
if (-not $PrNumber) { throw '-Post needs -PrNumber' }
$file = Join-Path ([IO.Path]::GetTempPath()) 'ai-review-comment.md'
[IO.File]::WriteAllText($file, $body, (New-Object Text.UTF8Encoding $false))
$existing = gh api "repos/$Repo/issues/$PrNumber/comments" --paginate --jq "[.[] | select(.body | contains(`"$marker`")) | .id] | first // empty"
if ($existing) { gh api -X PATCH "repos/$Repo/issues/comments/$existing" -F "body=@$file" | Out-Null }
else { gh api -X POST "repos/$Repo/issues/$PrNumber/comments" -F "body=@$file" | Out-Null }
Write-Host "Posted AI review to PR #$PrNumber"
