# Agent Stack Setup & Upgrade
# Copies the multi-agent workflow files into a target project.

param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Target project directory")]
    [string]$Target,

    [Parameter(HelpMessage = "Show what would change without copying anything")]
    [switch]$Diff
)

$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not (Test-Path $Target -PathType Container)) {
    Write-Error "Error: '$Target' is not a directory."
    exit 1
}

$Target = (Resolve-Path $Target).Path

# Files that are always updated (upstream-managed)
$UpstreamFiles = @(
    @{ Src = "agent-stack.md";                   Dest = ".claude/agent-stack.md" },
    @{ Src = "agents/overwatch.md";              Dest = "agents/overwatch.md" },
    @{ Src = "agents/ra.md";                     Dest = "agents/ra.md" },
    @{ Src = "agents/sa.md";                     Dest = "agents/sa.md" },
    @{ Src = "agents/developer.md";              Dest = "agents/developer.md" },
    @{ Src = "agents/sdet.md";                   Dest = "agents/sdet.md" },
    @{ Src = "templates/TASK-TEMPLATE.md";       Dest = "docs/tasks/TASK-TEMPLATE.md" },
    @{ Src = "templates/BUG-TEMPLATE.md";        Dest = "docs/tasks/BUG-TEMPLATE.md" }
)

# Files that are only copied on first setup (project-managed)
$ProjectFiles = @(
    @{ Src = "templates/CLAUDE.md";              Dest = "CLAUDE.md" },
    @{ Src = "templates/PROGRESS.md";            Dest = "docs/tasks/PROGRESS.md" },
    @{ Src = "templates/C4.md";                  Dest = "docs/architecture/C4.md" },
    @{ Src = "templates/TENETS.md";              Dest = "docs/architecture/TENETS.md" },
    @{ Src = "templates/SRS.md";                 Dest = "docs/requirements/SRS.md" },
    @{ Src = "templates/ADR-TEMPLATE.md";        Dest = "docs/decisions/ADR-TEMPLATE.md" }
)

function FilesAreEqual($path1, $path2) {
    if (-not (Test-Path $path1) -or -not (Test-Path $path2)) { return $false }
    $hash1 = (Get-FileHash $path1 -Algorithm SHA256).Hash
    $hash2 = (Get-FileHash $path2 -Algorithm SHA256).Hash
    return $hash1 -eq $hash2
}

if ($Diff) {
    Write-Host "Comparing agent stack files in: $Target"
    Write-Host ""

    $hasChanges = $false

    foreach ($file in $UpstreamFiles) {
        $srcPath = Join-Path $ScriptDir $file.Src
        $destPath = Join-Path $Target $file.Dest

        if (-not (Test-Path $destPath)) {
            Write-Host "--- $($file.Dest) (new file, does not exist in project)"
            $hasChanges = $true
        } elseif (-not (FilesAreEqual $srcPath $destPath)) {
            Write-Host "--- $($file.Dest) (has changes)"
            $srcLines = Get-Content $srcPath
            $destLines = Get-Content $destPath
            $comparison = Compare-Object $destLines $srcLines
            if ($comparison) {
                foreach ($line in $comparison) {
                    if ($line.SideIndicator -eq "=>") {
                        Write-Host "  + $($line.InputObject)" -ForegroundColor Green
                    } else {
                        Write-Host "  - $($line.InputObject)" -ForegroundColor Red
                    }
                }
            }
            Write-Host ""
            $hasChanges = $true
        }
    }

    if (-not $hasChanges) {
        Write-Host "No changes. Your project is up to date."
    } else {
        Write-Host ""
        Write-Host "Run without -Diff to apply these changes."
    }

    exit 0
}

Write-Host "Setting up agent stack in: $Target"
Write-Host ""

# Create directories
$dirs = @(
    ".claude",
    "agents",
    "docs/tasks",
    "docs/tasks/done",
    "docs/architecture",
    "docs/decisions",
    "docs/requirements",
    "docs/requirements/archive"
)
foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path (Join-Path $Target $dir) -Force | Out-Null
}

# Copy upstream-managed files (always updated)
foreach ($file in $UpstreamFiles) {
    $srcPath = Join-Path $ScriptDir $file.Src
    $destPath = Join-Path $Target $file.Dest

    if ((Test-Path $destPath) -and (FilesAreEqual $srcPath $destPath)) {
        Write-Host "  = $($file.Dest) (unchanged)"
    } elseif (Test-Path $destPath) {
        Copy-Item $srcPath $destPath
        Write-Host "  ~ $($file.Dest) (updated)"
    } else {
        Copy-Item $srcPath $destPath
        Write-Host "  + $($file.Dest) (new)"
    }
}

# Copy project-managed files (only on first setup)
foreach ($file in $ProjectFiles) {
    $srcPath = Join-Path $ScriptDir $file.Src
    $destPath = Join-Path $Target $file.Dest

    if (Test-Path $destPath) {
        Write-Host "  - $($file.Dest) (already exists, skipped)"
    } else {
        Copy-Item $srcPath $destPath
        Write-Host "  + $($file.Dest) (new)"
    }
}

# Hint about CLAUDE.md reference
$claudePath = Join-Path $Target "CLAUDE.md"
if ((Test-Path $claudePath) -and -not (Select-String -Path $claudePath -Pattern "agent-stack.md" -Quiet)) {
    Write-Host ""
    Write-Host "  Note: Your CLAUDE.md does not reference agent-stack.md."
    Write-Host "  Add this line so agents discover the workflow rules:"
    Write-Host ""
    Write-Host "    All agents must read ``.claude/agent-stack.md`` before starting work."
}

Write-Host ""
Write-Host "Done! Next steps:"
Write-Host "  1. Edit CLAUDE.md - fill in product vision, agent team, and commands"
Write-Host "  2. Edit docs/architecture/TENETS.md - define your architectural tenets"
Write-Host "  3. Edit docs/architecture/C4.md - sketch your initial architecture"
Write-Host "  4. Start working: invoke the RA to define requirements, then the SA to execute"
