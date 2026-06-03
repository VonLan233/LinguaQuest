#!/usr/bin/env pwsh
# Data Quality Audit Script for LinguaQuest Wordbooks
# Run: .\audit_wordbooks.ps1

$projectRoot = Resolve-Path "$PSScriptRoot\.."
$wordbooksDir = Join-Path $projectRoot "server\data\wordbooks"
$manifestPath = Join-Path $wordbooksDir "wordbooks_manifest.json"

$manifest = @{
    version = "1.0"
    generatedAt = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    wordbooks = @()
}

$allWords = @{}
$totalIssues = 0

function Test-FieldConsistency {
    param([array]$entries)
    $issues = @()
    $requiredFields = @('id','word','phoneticUK','phoneticUS','partOfSpeech','definitions','exampleSentences','examTags','difficulty')
    $optionalFields = @('audioUKUrl','audioUSUrl','englishDefinitions','collocations','synonyms','antonyms','derivatives','rootAffix','imageUrl')
    
    $emptyCounts = @{}
    foreach ($field in $requiredFields + $optionalFields) { $emptyCounts[$field] = 0 }
    
    $wordSet = @{}
    $idSet = @{}
    $duplicateWords = 0
    $duplicateIds = 0
    
    foreach ($entry in $entries) {
        # Check required fields
        foreach ($field in $requiredFields) {
            if ($null -eq $entry.$field -or ($entry.$field -is [string] -and $entry.$field -eq '') -or ($entry.$field -is [array] -and $entry.$field.Count -eq 0)) {
                $emptyCounts[$field]++
            }
        }
        # Check optional fields
        foreach ($field in $optionalFields) {
            $val = $entry.$field
            if ($null -eq $val -or ($val -is [string] -and $val -eq '') -or ($val -is [array] -and $val.Count -eq 0)) {
                $emptyCounts[$field]++
            }
        }
        
        # Check duplicate words (case-insensitive)
        $w = $entry.word.ToString().ToLower().Trim()
        if ($wordSet.ContainsKey($w)) { $duplicateWords++ } else { $wordSet[$w] = 1 }
        
        # Check duplicate IDs
        $id = $entry.id.ToString()
        if ($idSet.ContainsKey($id)) { $duplicateIds++ } else { $idSet[$id] = 1 }
    }
    
    return @{
        emptyCounts = $emptyCounts
        duplicateWords = $duplicateWords
        duplicateIds = $duplicateIds
        totalEntries = $entries.Count
    }
}

$files = Get-ChildItem -Path $wordbooksDir -Filter "*.json" | Where-Object { $_.Name -ne "wordbooks_manifest.json" }

foreach ($file in $files) {
    $bookId = $file.BaseName
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $entries = $content | ConvertFrom-Json
    
    $audit = Test-FieldConsistency -entries $entries
    
    # Compute coverage
    $coverage = @{}
    foreach ($field in $audit.emptyCounts.Keys) {
        $coverage[$field] = [math]::Round((1 - $audit.emptyCounts[$field] / $audit.totalEntries) * 100, 1)
    }
    
    # Determine category and exam type from filename
    $examType = switch ($bookId) {
        'beginner' { 'Beginner' }
        'gmat' { 'GMAT' }
        'gre' { 'GRE' }
        'ielts' { 'IELTS' }
        'sat' { 'SAT' }
        'toefl' { 'TOEFL' }
        default { $bookId.ToUpper() }
    }
    
    $category = switch ($bookId) {
        'beginner' { '基础英语' }
        default { '出国考试' }
    }
    
    $title = switch ($bookId) {
        'beginner' { '初级英语词汇' }
        'gmat' { 'GMAT核心词汇' }
        'gre' { 'GRE核心词汇' }
        'ielts' { '雅思核心词汇' }
        'sat' { 'SAT核心词汇' }
        'toefl' { '托福核心词汇' }
    }
    
    $description = switch ($bookId) {
        'beginner' { '面向英语初学者的基础词汇，覆盖日常交流和简单阅读场景' }
        'gmat' { 'GMAT考试高频核心词汇，覆盖逻辑、数学、阅读全场景' }
        'gre' { 'GRE考试高频核心词汇，覆盖填空、阅读、写作全场景' }
        'ielts' { '雅思考试高频核心词汇，覆盖听说读写全场景' }
        'sat' { 'SAT考试高频核心词汇，覆盖阅读、文法、写作全场景' }
        'toefl' { '托福考试高频核心词汇，覆盖听说读写全场景' }
    }
    
    $manifest.wordbooks += @{
        id = $bookId
        title = $title
        category = $category
        examType = $examType
        coverUrl = ""
        totalWords = $audit.totalEntries
        description = $description
        fileName = $file.Name
        dataQuality = @{
            duplicateWords = $audit.duplicateWords
            duplicateIds = $audit.duplicateIds
            fieldCoverage = $coverage
        }
    }
    
    # Global duplicate check across all books
    foreach ($entry in $entries) {
        $w = $entry.word.ToString().ToLower().Trim()
        if (-not $allWords.ContainsKey($w)) {
            $allWords[$w] = @($bookId)
        } else {
            $allWords[$w] += $bookId
        }
    }
    
    Write-Host "[$bookId] $($audit.totalEntries) words | dup-words=$($audit.duplicateWords) dup-ids=$($audit.duplicateIds)"
}

# Cross-book duplicates
$crossBookDups = $allWords.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 }
Write-Host "`nCross-book duplicate words: $($crossBookDups.Count)"

$manifest | ConvertTo-Json -Depth 10 | Set-Content $manifestPath -Encoding UTF8
Write-Host "`nManifest written to: $manifestPath"
