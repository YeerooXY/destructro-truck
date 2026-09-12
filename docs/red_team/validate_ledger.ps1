param(
    [string]$IndexPath = (Join-Path $PSScriptRoot '../../assembly/generated/red_team_review_index.json'),
    [string]$RepositoryRoot = (Join-Path $PSScriptRoot '../..')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-Ledger([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "Red Team ledger: $Message" }
}

function Assert-Text($Value, [string]$Label) {
    Assert-Ledger ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value)) "$Label must contain text"
}

function Read-Utc($Value, [string]$Label) {
    Assert-Text $Value $Label
    Assert-Ledger ($Value -match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$') "$Label must use UTC YYYY-MM-DDTHH:MM:SSZ"
    return [DateTimeOffset]::Parse($Value)
}

$ledger = Get-Content -LiteralPath $IndexPath -Raw -Encoding UTF8 | ConvertFrom-Json
$repoPath = (Resolve-Path -LiteralPath $RepositoryRoot).Path.TrimEnd('\', '/')
Assert-Ledger ($ledger.project_id -eq 'destructro-truck') 'unexpected project_id'
Assert-Ledger ($ledger.schema_version -eq '0.2.0') 'unsupported schema_version'

$events = @{}
foreach ($event in $ledger.reverification_events) {
    Assert-Ledger ($event.event_id -match '^RV-\d{4}$') 'invalid re-verification event ID'
    Assert-Ledger (-not $events.ContainsKey($event.event_id)) "duplicate event $($event.event_id)"
    foreach ($field in @('finding_id', 'reviewer_identity', 'fix_reference', 'fix_commit_or_artifact', 'original_reproduction')) {
        Assert-Text $event.$field "$($event.event_id).$field"
    }
    $null = Read-Utc $event.performed_at "$($event.event_id).performed_at"
    Assert-Ledger ($event.result -in @('pass', 'fail', 'inconclusive')) "invalid result for $($event.event_id)"
    Assert-Ledger (@($event.evidence).Count -gt 0) "$($event.event_id) lacks reproduction evidence"
    foreach ($evidence in $event.evidence) { Assert-Text $evidence "$($event.event_id).evidence" }
    $events[$event.event_id] = $event
}

$reviewIds = @{}
$findingIds = @{}
$requiredFields = @(
    'review_id', 'reviewed_task_pr_or_commit', 'scope', 'reviewer_identity',
    'started_at', 'completed_at', 'reviewed_files_and_contracts', 'outcome',
    'severity_summary', 'critical_findings', 'follow_up_task_references',
    'reverification_status', 'review_kind', 'report_path', 'evidence', 'findings'
)

foreach ($review in $ledger.reviews) {
    foreach ($field in $requiredFields) {
        Assert-Ledger ($review.PSObject.Properties.Name -contains $field) "review is missing $field"
    }
    Assert-Ledger ($review.review_id -match '^RT-\d{4}$') 'invalid review ID'
    Assert-Ledger (-not $reviewIds.ContainsKey($review.review_id)) "duplicate review $($review.review_id)"
    $reviewIds[$review.review_id] = $true
    Assert-Ledger ($review.review_kind -in @('planning', 'implementation', 'integration', 'release')) 'invalid review kind'
    Assert-Ledger ($review.outcome -in @('in_progress', 'no_findings', 'findings', 'blocked')) 'invalid review outcome'
    Assert-Text $review.scope "$($review.review_id).scope"
    Assert-Text $review.reviewer_identity "$($review.review_id).reviewer_identity"
    $start = Read-Utc $review.started_at "$($review.review_id).started_at"
    if ($review.outcome -eq 'in_progress') {
        Assert-Ledger ($null -eq $review.completed_at) 'in-progress review cannot have completed_at'
    } else {
        $completed = Read-Utc $review.completed_at "$($review.review_id).completed_at"
        Assert-Ledger ($completed -ge $start) 'review completion precedes start'
        Assert-Ledger (@($review.evidence).Count -gt 0) 'completed review lacks evidence'
    }
    foreach ($evidence in $review.evidence) { Assert-Text $evidence "$($review.review_id).evidence" }
    Assert-Ledger (@($review.reviewed_task_pr_or_commit.task_ids).Count -gt 0) 'review has no task IDs'
    Assert-Ledger ($review.reviewed_task_pr_or_commit.commit -match '^[0-9a-f]{40}$') 'review requires exact full commit SHA'
    if ($null -eq $review.reviewed_task_pr_or_commit.pr_url) {
        Assert-Text $review.reviewed_task_pr_or_commit.no_pr_reason 'no_pr_reason'
    }
    Assert-Text $review.reviewed_task_pr_or_commit.working_tree_state 'working_tree_state'
    Assert-Ledger (@($review.reviewed_files_and_contracts).Count -gt 0) 'review has no file/contract scope'
    foreach ($file in $review.reviewed_files_and_contracts) { Assert-Text $file 'reviewed file/contract' }
    Assert-Text $review.report_path 'report_path'
    $reportPath = [IO.Path]::GetFullPath((Join-Path $repoPath $review.report_path))
    $reportRoot = [IO.Path]::GetFullPath((Join-Path $repoPath 'docs/red_team/reviews')).TrimEnd('\') + '\'
    Assert-Ledger ($reportPath.StartsWith($reportRoot, [StringComparison]::OrdinalIgnoreCase)) 'report escapes review directory'
    Assert-Ledger (Test-Path -LiteralPath $reportPath -PathType Leaf) "missing report $($review.report_path)"

    $counts = @{ critical = 0; high = 0; medium = 0; low = 0 }
    $resolvedCount = 0
    foreach ($finding in $review.findings) {
        Assert-Ledger ($finding.finding_id -match ('^' + $review.review_id + '-F[1-9]\d*$')) 'invalid finding ID'
        Assert-Ledger (-not $findingIds.ContainsKey($finding.finding_id)) "duplicate finding $($finding.finding_id)"
        $findingIds[$finding.finding_id] = $true
        Assert-Ledger ($finding.severity -in @('critical', 'high', 'medium', 'low')) 'invalid severity'
        $counts[$finding.severity]++
        foreach ($field in @('title', 'classification', 'owner', 'follow_up_reference', 'follow_up_scope', 'expected_behavior', 'reproduction', 'evidence')) {
            Assert-Text $finding.$field "$($finding.finding_id).$field"
        }
        Assert-Ledger ($finding.follow_up_reference -in $review.follow_up_task_references) 'finding follow-up absent from review references'
        Assert-Ledger ($finding.status -in @('open', 'fix_claimed', 'resolved', 'reopened')) 'invalid finding status'
        if ($finding.status -in @('fix_claimed', 'resolved')) {
            Assert-Text $finding.fix_reference "$($finding.finding_id).fix_reference"
            Assert-Text $finding.fix_commit_or_artifact "$($finding.finding_id).fix_commit_or_artifact"
            Assert-Text $finding.fix_claim_evidence "$($finding.finding_id).fix_claim_evidence"
        }
        if ($finding.status -eq 'resolved') {
            $resolvedCount++
            Assert-Ledger ($null -ne $finding.reverification_event_id -and $events.ContainsKey($finding.reverification_event_id)) 'resolved finding requires a separate re-verification event'
            $event = $events[$finding.reverification_event_id]
            Assert-Ledger ($event.finding_id -eq $finding.finding_id -and $event.result -eq 'pass') 'closure event must pass for the same finding'
            Assert-Ledger ($event.fix_reference -eq $finding.fix_reference -and $event.fix_commit_or_artifact -eq $finding.fix_commit_or_artifact) 'closure event must test the claimed fixing revision'
            Assert-Ledger ($review.outcome -ne 'in_progress') 'finish the original review before re-verification closure'
            Assert-Ledger ((Read-Utc $event.performed_at 're-verification time') -ge $completed) 're-verification predates original completed review'
            $latest = @($ledger.reverification_events | Where-Object { $_.finding_id -eq $finding.finding_id } | Sort-Object performed_at,event_id)[-1]
            Assert-Ledger ($latest.event_id -eq $event.event_id) 'closure must use latest re-verification event'
        }
    }
    foreach ($severity in $counts.Keys) {
        Assert-Ledger ($review.severity_summary.$severity -eq $counts[$severity]) "incorrect $severity severity count"
    }
    $expectedCritical = @($review.findings | Where-Object { $_.severity -eq 'critical' } | ForEach-Object { $_.finding_id } | Sort-Object)
    Assert-Ledger ((@($review.critical_findings | Sort-Object) -join ',') -eq ($expectedCritical -join ',')) 'critical finding IDs do not match findings'
    $findingCount = @($review.findings).Count
    if ($review.outcome -eq 'no_findings') { Assert-Ledger ($findingCount -eq 0) 'no_findings outcome contains findings' }
    if ($review.outcome -eq 'findings') { Assert-Ledger ($findingCount -gt 0) 'findings outcome has no findings' }
    $expectedStatus = if ($findingCount -eq 0) { 'not_required' } elseif ($resolvedCount -eq $findingCount) { 'complete' } elseif ($resolvedCount -gt 0) { 'partial' } else { 'pending' }
    Assert-Ledger ($review.reverification_status -eq $expectedStatus) "incorrect re-verification status for $($review.review_id)"
}

foreach ($event in $ledger.reverification_events) {
    Assert-Ledger ($findingIds.ContainsKey($event.finding_id)) "orphan re-verification event $($event.event_id)"
}
Write-Output "Red Team ledger valid: $($reviewIds.Count) reviews, $($findingIds.Count) findings, $($events.Count) re-verification events."
