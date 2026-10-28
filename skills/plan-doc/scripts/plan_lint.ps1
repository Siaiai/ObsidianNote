<#
plan_lint.ps1 - validate Obsidian planning documents.

Usage:
  powershell -NoProfile -ExecutionPolicy Bypass -File plan_lint.ps1 -Path <file-or-dir> [-Strict]

Exit codes:
  0 = no errors (warnings allowed unless -Strict)
  1 = errors found (or warnings with -Strict)
  2 = path not found
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$Path,
    [switch]$Strict,
    [switch]$PlanOnly
)

$ErrorActionPreference = 'Stop'
try { [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false) } catch { }
$issues = New-Object System.Collections.Generic.List[object]

function Add-Issue {
    param([string]$Level, [string]$Code, [string]$File, [int]$Line, [string]$Message)
    $issues.Add([pscustomobject]@{
            Level   = $Level
            Code    = $Code
            File    = $File
            Line    = $Line
            Message = $Message
        }) | Out-Null
}

function Get-TargetFiles {
    param([string[]]$Inputs)
    $list = New-Object System.Collections.Generic.List[string]
    foreach ($p in $Inputs) {
        if (-not (Test-Path -LiteralPath $p)) {
            Write-Output "ERROR PATH: $p not found"
            exit 2
        }
        $item = Get-Item -LiteralPath $p -Force
        if ($item.PSIsContainer) {
            Get-ChildItem -LiteralPath $item.FullName -Filter *.md -File -Recurse -Force |
                Where-Object {
                    $_.FullName -notmatch '[\\/]\.(obsidian|git|trash)[\\/]' -and
                    $_.FullName -notmatch '[\\/](node_modules|build|dist|out|target|vendor|skills)[\\/]'
                } |
                Where-Object {
                    if (-not $PlanOnly) { return $true }
                    $head = Get-Content -LiteralPath $_.FullName -TotalCount 60 -Encoding UTF8
                    return (($head -join "`n") -match 'plan-doc:v1')
                } |
                ForEach-Object { $list.Add($_.FullName) }
        }
        else {
            $list.Add($item.FullName)
        }
    }
    return $list
}

function Parse-FrontMatter {
    param([string[]]$Lines)
    if ($Lines.Count -lt 2 -or $Lines[0].Trim() -ne '---') { return $null }
    $end = -1
    for ($i = 1; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i].Trim() -eq '---') { $end = $i; break }
    }
    if ($end -lt 0) { return $null }
    $fm = @{ __end = $end }
    $lastKey = $null
    for ($i = 1; $i -lt $end; $i++) {
        $line = $Lines[$i]
        if ($line -match '^\s+-\s*(.*)$') {
            if ($lastKey) {
                $v = $Matches[1].Trim()
                $v = $v -replace '^"', '' -replace '"$', ''
                if ($null -eq $fm[$lastKey] -or $fm[$lastKey] -is [string]) {
                    $old = $fm[$lastKey]
                    $fm[$lastKey] = @()
                    if ($old) { $fm[$lastKey] += $old }
                }
                $fm[$lastKey] += $v
            }
            continue
        }
        if ($line -match '^([^\s:#][^:]*?):\s*(.*)$') {
            $lastKey = $Matches[1].Trim()
            $v = $Matches[2].Trim()
            $v = $v -replace '^"', '' -replace '"$', ''
            $fm[$lastKey] = $v
        }
    }
    return $fm
}

function Get-FmText {
    param($Fm, [string]$Key)
    if ($null -eq $Fm -or -not $Fm.ContainsKey($Key)) { return '' }
    $v = $Fm[$Key]
    if ($v -is [array]) { return (($v | Where-Object { $_ -ne '' }) -join ',') }
    return [string]$v
}

function Get-SectionRange {
    param($Secs, [int]$Num, [int]$Count)
    $hit = $null
    foreach ($s in $Secs) { if ($s.Num -eq $Num) { $hit = $s; break } }
    if ($null -eq $hit) { return @(-1, -1) }
    $end = $Count - 1
    foreach ($s in $Secs) {
        if ($s.Index -gt $hit.Index) { $end = $s.Index - 1; break }
    }
    return @($hit.Index, $end)
}

function Test-PlanFile {
    param([string]$File)

    $lines = @(Get-Content -LiteralPath $File -Encoding UTF8)
    if ($lines.Count -eq 0) {
        Add-Issue 'ERROR' 'DOC-000' $File 1 'empty file'
        return
    }

    $inFence = New-Object 'bool[]' $lines.Count
    $fence = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $t = $lines[$i].TrimStart()
        if ($t.StartsWith('```')) { $inFence[$i] = $true; $fence = -not $fence; continue }
        $inFence[$i] = $fence
    }

    $inComment = New-Object 'bool[]' $lines.Count
    $comment = $false
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '<!--') { $comment = $true }
        $inComment[$i] = $comment
        if ($lines[$i] -match '-->') { $comment = $false }
    }

    $fm = Parse-FrontMatter -Lines $lines
    $bodyStart = 0
    if ($null -ne $fm) { $bodyStart = [int]$fm['__end'] + 1 }

    $timeReStrict = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$'
    $timeReLoose = '^\d{4}-\d{2}-\d{2}([T ]\d{2}:\d{2}(:\d{2})?)?$'
    $obsidianMode = $false
    if ($null -ne $fm) {
        foreach ($k in @('领域', '项目', '任务', '状态', '创建时间', '截止时间', '完成时间', '相关任务')) {
            if ($fm.ContainsKey($k)) { $obsidianMode = $true; break }
        }
    }

    if ($null -ne $fm -and $obsidianMode) {
        $created = Get-FmText $fm '创建时间'
        if (-not $created) {
            Add-Issue 'ERROR' 'FM-002' $File 2 'missing 创建时间'
        }
        elseif ($created -notmatch $timeReStrict) {
            Add-Issue 'ERROR' 'FM-002' $File 2 "创建时间 must be YYYY-MM-DDTHH:mm:ss, got '$created'"
        }
        foreach ($k in @('截止时间', '完成时间')) {
            $v = Get-FmText $fm $k
            if ($v -and $v -notmatch $timeReStrict) {
                Add-Issue 'ERROR' 'FM-002' $File 2 "$k must be YYYY-MM-DDTHH:mm:ss, got '$v'"
            }
        }

        $status = Get-FmText $fm '状态'
        $done = Get-FmText $fm '完成时间'
        $known = @('待办', '进行', '完成', '规划中', '进行中', '已归档', '草稿', '已发布', '待学', '已掌握')
        if (-not $status) {
            Add-Issue 'ERROR' 'FM-003' $File 2 'missing 状态'
        }
        elseif ($known -notcontains $status) {
            Add-Issue 'WARN' 'FM-003' $File 2 "unknown 状态 '$status'"
        }
        if ($status -eq '完成' -and -not $done) {
            Add-Issue 'ERROR' 'FM-004' $File 2 '状态=完成 but 完成时间 is empty'
        }
        if ($status -and $status -ne '完成' -and $done) {
            Add-Issue 'ERROR' 'FM-005' $File 2 "状态=$status but 完成时间 is set ($done)"
        }
        if (-not (Get-FmText $fm '项目')) {
            Add-Issue 'WARN' 'FM-006' $File 2 'missing 项目'
        }
        $types = Get-FmText $fm '类型'
        if (-not (Get-FmText $fm '任务') -and $types -match '开发|会议|方案|调研|文档') {
            Add-Issue 'WARN' 'FM-006' $File 2 'missing 任务 (required for task notes)'
        }
        $rel = $fm['相关任务']
        if ($rel -is [array] -and ($rel -contains '')) {
            Add-Issue 'WARN' 'FM-007' $File 2 '相关任务 should be an empty line, not "" item'
        }
    }
    elseif ($null -ne $fm) {
        $status = Get-FmText $fm 'status'
        $done = Get-FmText $fm 'completed'
        foreach ($k in @('created', 'updated', 'completed')) {
            $v = Get-FmText $fm $k
            if ($v -and $v -notmatch $timeReLoose) {
                Add-Issue 'WARN' 'FM-002' $File 2 "$k should be YYYY-MM-DD or ISO datetime, got '$v'"
            }
        }
        if ($status) {
            $knownStatus = @('active', 'done', 'paused', 'cancelled', 'canceled', 'todo', 'doing', 'blocked',
                '待办', '进行', '完成')
            if ($knownStatus -notcontains $status.ToLower()) {
                Add-Issue 'WARN' 'FM-003' $File 2 "unknown status '$status'"
            }
            if (($status.ToLower() -in @('done', 'cancelled', 'canceled')) -and -not $done) {
                Add-Issue 'WARN' 'FM-004' $File 2 "status=$status but completed is empty"
            }
            if (($status.ToLower() -in @('active', 'doing', 'todo', '进行', '待办')) -and $done) {
                Add-Issue 'ERROR' 'FM-005' $File 2 "status=$status but completed is set ($done)"
            }
        }
    }

    $head = ''
    if ($bodyStart -lt $lines.Count) {
        $headEnd = [Math]::Min($lines.Count - 1, $bodyStart + 80)
        $head = ($lines[$bodyStart..$headEnd] -join "`n")
    }
    $strictDoc = $head -match 'plan-doc:v1'
    $hasAiEntry = $false
    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        if (-not $inFence[$i] -and -not $inComment[$i] -and $lines[$i] -match '^##\s*AI\s*入口') {
            $hasAiEntry = $true
            break
        }
    }

    $secs = @()
    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        if ($inFence[$i] -or $inComment[$i]) { continue }
        if ($lines[$i] -match '^##\s+(\d+)\.') {
            $secs += [pscustomobject]@{ Index = $i; Num = [int]$Matches[1] }
        }
    }

    $lastUpdate = ''
    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        if (-not $inFence[$i] -and -not $inComment[$i] -and $lines[$i] -match '最后更新[:：]\s*(\d{4}-\d{2}-\d{2})') {
            $lastUpdate = $Matches[1]
            break
        }
    }

    if ($strictDoc) {
        if (-not $hasAiEntry) {
            Add-Issue 'WARN' 'DOC-001' $File ($bodyStart + 1) 'missing "## AI 入口" block'
        }
        if (-not $lastUpdate) {
            Add-Issue 'WARN' 'DOC-002' $File ($bodyStart + 1) 'missing "最后更新"'
        }
        foreach ($n in @(0, 1, 2, 5)) {
            if (-not ($secs | Where-Object { $_.Num -eq $n })) {
                Add-Issue 'ERROR' 'DOC-003' $File ($bodyStart + 1) "missing section $n"
            }
        }
        $hasMechanismReg = $false
        for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
            if (-not $inFence[$i] -and -not $inComment[$i] -and $lines[$i] -match '^###\s*0\.4') {
                $hasMechanismReg = $true
                break
            }
        }
        if (-not $hasMechanismReg) {
            Add-Issue 'WARN' 'DOC-006' $File ($bodyStart + 1) 'missing "### 0.4 机制登记" (一功能一机制)'
        }
    }

    if (-not $lastUpdate -and $null -ne $fm) {
        $u = Get-FmText $fm 'updated'
        if ($u -match '^(\d{4}-\d{2}-\d{2})') { $lastUpdate = $Matches[1] }
    }

    $status2 = ''
    if ($null -ne $fm) {
        $status2 = Get-FmText $fm '状态'
        if (-not $status2) { $status2 = Get-FmText $fm 'status' }
    }
    $stamp = $lastUpdate
    if ($stamp -and ($status2 -eq '进行' -or $status2 -eq '进行中' -or
            $status2.ToLower() -eq 'active' -or $status2.ToLower() -eq 'doing')) {
        try {
            $d = [datetime]::ParseExact($stamp, 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
            if (((Get-Date).Date - $d.Date).TotalDays -gt 7) {
                Add-Issue 'WARN' 'DOC-004' $File ($bodyStart + 1) "status=$status2 but 最后更新 is $stamp (>7 days)"
            }
        }
        catch { }
    }

    $taskLevel = if ($strictDoc) { 'ERROR' } else { 'WARN' }

    $r1 = Get-SectionRange $secs 1 $lines.Count
    if ($r1[0] -ge 0) {
        for ($i = $r1[0]; $i -le $r1[1]; $i++) {
            if (-not $inFence[$i] -and -not $inComment[$i] -and $lines[$i] -match '^\s*-\s*\[[xX]\]') {
                Add-Issue $taskLevel 'TASK-001' $File ($i + 1) 'checked item in 待办 section; move it to 归档'
            }
        }
    }

    $r5 = Get-SectionRange $secs 5 $lines.Count
    if ($r5[0] -ge 0) {
        for ($i = $r5[0]; $i -le $r5[1]; $i++) {
            if ($inFence[$i] -or $inComment[$i]) { continue }
            $l = $lines[$i]
            if ($l -match '^\s*-\s*\[[xX]\]' -and $l -match '\b(T\d+-\d+|V-\d+)\b') {
                if ($l -notmatch '验证') {
                    Add-Issue $taskLevel 'TASK-002' $File ($i + 1) 'record has no 验证: ...'
                }
                if ($l -notmatch '结果') {
                    Add-Issue $taskLevel 'TASK-002' $File ($i + 1) 'record has no 结果: ...'
                }
            }
        }
    }

    $bodyLines = for ($i = 0; $i -lt $lines.Count; $i++) {
        if (-not $inFence[$i] -and -not $inComment[$i]) { $lines[$i] }
    }
    $joined = $bodyLines -join "`n"
    if ($joined -match 'YYMMDD任务名|\[\[项目名\]\]|\{\{date:|\{项目名\}|\{YYMMDD\}|\{YYYY-MM-DD|\{标题\}') {
        Add-Issue 'WARN' 'DOC-005' $File 1 'template placeholders not replaced (项目名 / YYMMDD / YYYY-MM-DD / {{date:...}})'
    }
    $r1b = Get-SectionRange $secs 1 $lines.Count
    $r6 = Get-SectionRange $secs 6 $lines.Count
    if ($r1b[0] -ge 0) {
        for ($i = $r1b[0]; $i -le $r1b[1]; $i++) {
            if (-not $inFence[$i] -and -not $inComment[$i] -and $lines[$i] -match '\*\*T1-1 (动作|名称)\*\*') {
                Add-Issue 'WARN' 'DOC-005' $File ($i + 1) 'placeholder task T1-1 not replaced'
                break
            }
        }
    }
    $taskDefs = @{}
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($inFence[$i] -or $inComment[$i]) { continue }
        $l = $lines[$i]
        $id = $null
        if ($r1b[0] -ge 0 -and $i -ge $r1b[0] -and $i -le $r1b[1] -and
            $l -match '^\s*[-*]\s*\[[ xX]\]\s*\*\*([A-Z]\d+-\d+)\b') {
            $id = $Matches[1]
        }
        elseif ($r6[0] -ge 0 -and $i -ge $r6[0] -and $i -le $r6[1] -and
            $l -match '^\|\s*([A-Z]\d+-\d+)\s*\|') {
            $id = $Matches[1]
        }
        if ($id) {
            if ($taskDefs.ContainsKey($id)) {
                Add-Issue 'ERROR' 'TASK-003' $File ($i + 1) "duplicate task definition $id (first at line $($taskDefs[$id]))"
            }
            else {
                $taskDefs[$id] = $i + 1
            }
        }
    }

    $r4 = Get-SectionRange $secs 4 $lines.Count
    $changeTypes = @('新增', '修改', '删除', '延期', '否决', '待定')
    $cDefs = @{}
    if ($r4[0] -ge 0) {
        for ($i = $r4[0]; $i -le $r4[1]; $i++) {
            if ($inFence[$i] -or $inComment[$i]) { continue }
            $l = $lines[$i]
            if ($l -match '^\|\s*(C\d+)\s*\|') {
                $cid = $Matches[1]
                if ($cDefs.ContainsKey($cid)) {
                    Add-Issue 'ERROR' 'CHG-003' $File ($i + 1) "duplicate change definition $cid"
                }
                else {
                    $cDefs[$cid] = $i + 1
                }
                $cells = $l.Trim().Trim('|').Split('|')
                if ($cells.Count -ge 3) {
                    $t = $cells[2].Trim()
                    if ($t -and ($changeTypes -notcontains $t)) {
                        Add-Issue 'WARN' 'CHG-002' $File ($i + 1) "unknown change type '$t'"
                    }
                }
            }
        }
    }

    if ($cDefs.Count -gt 0) {
        $reportedRefs = @{}
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($inFence[$i] -or $inComment[$i]) { continue }
            $l = $lines[$i]
            if ($l -match '^\|\s*C\d+\s*\|') { continue }
            foreach ($m in [regex]::Matches($l, '\bC\d+\b')) {
                $cid = $m.Value
                if (-not $cDefs.ContainsKey($cid) -and -not $reportedRefs.ContainsKey($cid)) {
                    $reportedRefs[$cid] = $true
                    Add-Issue 'WARN' 'CHG-001' $File ($i + 1) "reference $cid has no definition in 变更记录"
                }
            }
        }
    }

    $i = 0
    while ($i -lt $lines.Count) {
        if ($inFence[$i] -or $inComment[$i] -or $lines[$i] -notmatch '^\s*\|') { $i++; continue }
        $expected = -1
        $warned = $false
        while ($i -lt $lines.Count -and -not $inFence[$i] -and -not $inComment[$i] -and $lines[$i] -match '^\s*\|') {
            $clean = $lines[$i] -replace '`[^`]*`', ''
            $clean = $clean -replace '\\\|', ''
            $cnt = ([regex]::Matches($clean, '\|')).Count
            if ($expected -lt 0) { $expected = $cnt }
            elseif ($cnt -ne $expected -and -not $warned) {
                Add-Issue 'WARN' 'TBL-001' $File ($i + 1) "table column count $cnt != $expected"
                $warned = $true
            }
            $i++
        }
    }

    $vague = '基本完成|基本一致|基本可用|大致完成|大概完成|应该没问题|应该可以|确保正确|确保完成|差不多|可能已经'
    $vw = 0
    for ($i = $bodyStart; $i -lt $lines.Count; $i++) {
        if ($inFence[$i] -or $inComment[$i]) { continue }
        if ($vw -ge 5) { break }
        if ($lines[$i] -match $vague) {
            Add-Issue 'WARN' 'TXT-001' $File ($i + 1) 'vague wording; use concrete numbers/commands'
            $vw++
        }
    }
}

$files = Get-TargetFiles -Inputs $Path
if ($files.Count -eq 0) {
    Write-Output 'no markdown files found'
    exit 0
}

foreach ($f in $files) { Test-PlanFile -File $f }

$errs = @($issues | Where-Object { $_.Level -eq 'ERROR' })
$warns = @($issues | Where-Object { $_.Level -eq 'WARN' })

foreach ($f in $files) {
    Write-Output "FILE: $f"
    $fi = @($issues | Where-Object { $_.File -eq $f })
    if ($fi.Count -eq 0) {
        Write-Output '  OK'
        continue
    }
    foreach ($x in ($fi | Sort-Object Line, Code)) {
        Write-Output ("  {0,-5} {1,-8} L{2,-4} {3}" -f $x.Level, $x.Code, $x.Line, $x.Message)
    }
}

Write-Output ''
Write-Output ("SUMMARY: {0} error(s), {1} warning(s), {2} file(s)" -f $errs.Count, $warns.Count, $files.Count)
if ($errs.Count -gt 0) { exit 1 }
if ($Strict -and $warns.Count -gt 0) { exit 1 }
exit 0
