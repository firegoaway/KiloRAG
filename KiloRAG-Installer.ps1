# KiloRAG_Complete_Installer.ps1
# Полный установщик системы KiloRAG для Windows с загрузкой репозитория
# Требуется запуск от администратора

param(
    [string]$InstallPath = "C:\KiloRAG",
    [string]$NodeVersion = "24.11.1"
)

Write-Host "=== УСТАНОВЩИК KILORAG ===" -ForegroundColor Green
Write-Host "Начало установки системы автоматизированного расчета категорий по пожарной опасности" -ForegroundColor Yellow

# Проверка прав администратора
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Этот скрипт требует прав администратора. Запустите PowerShell от имени администратора."
    exit 1
}

# Создание рабочей директории
Write-Host "`n1. Создание рабочей директории..." -ForegroundColor Cyan
if (!(Test-Path $InstallPath)) {
    New-Item -ItemType Directory -Path $InstallPath -Force
    Write-Host "   Создана директория: $InstallPath" -ForegroundColor Green
} else {
    Write-Host "   Директория уже существует: $InstallPath" -ForegroundColor Yellow
}

Set-Location $InstallPath

# Скачивание репозитория KiloRAG
Write-Host "`n2. Скачивание репозитория KiloRAG..." -ForegroundColor Cyan
$repoUrl = "https://github.com/firegoaway/KiloRAG/archive/refs/heads/main.zip"
$zipFile = "$InstallPath\KiloRAG-main.zip"
$extractPath = "$InstallPath\KiloRAG-main"
$finalPath = $InstallPath

try {
    # Скачивание ZIP-архива
    Write-Host "   Загрузка архива с GitHub..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri $repoUrl -OutFile $zipFile
    
    if (Test-Path $zipFile) {
        Write-Host "   Архив успешно скачан ($([math]::Round((Get-Item $zipFile).Length / 1MB, 2)) MB)" -ForegroundColor Green
        
        # Распаковка архива
        Write-Host "   Распаковка архива..." -ForegroundColor Yellow
        Expand-Archive -Path $zipFile -DestinationPath $InstallPath -Force
        
        if (Test-Path $extractPath) {
            Write-Host "   Архив распакован" -ForegroundColor Green
            
            # Перемещение файлов из временной папки в целевую
            Write-Host "   Перенос файлов..." -ForegroundColor Yellow
            Get-ChildItem -Path $extractPath | Move-Item -Destination $finalPath -Force
            
            # Удаление временной папки
            Remove-Item -Path $extractPath -Recurse -Force
            Write-Host "   Файлы репозитория успешно размещены" -ForegroundColor Green
        }
        
        # Удаление ZIP-архива
        Remove-Item -Path $zipFile -Force
    }
}
catch {
    Write-Error "   Ошибка при скачивании репозитория: $_"
    Write-Host "   Продолжаем установку с созданием базовой структуры..." -ForegroundColor Yellow
    # Создаем базовую структуру в случае ошибки скачивания
    Create-BaseStructure -InstallPath $InstallPath
}

# Установка Node.js
Write-Host "`n3. Установка Node.js..." -ForegroundColor Cyan
$nodeCheck = Get-Command node -ErrorAction SilentlyContinue
if ($nodeCheck) {
    $currentVersion = (node --version)
    Write-Host "   Node.js уже установлен: $currentVersion" -ForegroundColor Yellow
    
    # Проверка совместимости версии 
    if ($currentVersion -lt "v24.11.1") {
        Write-Host "   Требуется обновление до версии 24.11.1 или выше" -ForegroundColor Red
        $installNode = $true
    } else {
        $installNode = $false
    }
} else {
    $installNode = $true
}

if ($installNode) {
    Write-Host "   Загрузка и установка Node.js LTS..." -ForegroundColor Yellow
    $nodeInstaller = "$env:TEMP\nodejs-installer.msi"
    
    # Загрузка официального дистрибутива Node.js 
    try {
        $nodeUrl = "https://nodejs.org/dist/v20.18.0/node-v20.18.0-x64.msi"
        Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller
        
        # Тихая установка
        Start-Process msiexec -ArgumentList "/i", "$nodeInstaller", "/quiet", "/norestart" -Wait
        Write-Host "   Node.js успешно установлен" -ForegroundColor Green
        
        # Обновление PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }
    catch {
        Write-Error "   Ошибка при установке Node.js: $_"
        exit 1
    }
    finally {
        if (Test-Path $nodeInstaller) {
            Remove-Item $nodeInstaller
        }
    }
}

# Проверка установки Node.js и npm
Write-Host "`n4. Проверка установки..." -ForegroundColor Cyan
$nodeVersion = (node --version)
$npmVersion = (npm --version)
Write-Host "   Node.js: $nodeVersion" -ForegroundColor Green
Write-Host "   npm: $npmVersion" -ForegroundColor Green

# Установка Qwen-Code
Write-Host "`n5. Установка Qwen-Code..." -ForegroundColor Cyan
try {
    npm install -g @qwen-code/qwen-code
    Write-Host "   Qwen-Code успешно установлен" -ForegroundColor Green
}
catch {
    Write-Error "   Ошибка при установке Qwen-Code: $_"
    exit 1
}

# Установка Visual Studio Code
Write-Host "`n6. Установка Visual Studio Code..." -ForegroundColor Cyan
$vscCheck = Get-Command code -ErrorAction SilentlyContinue
if (-not $vscCheck) {
    Write-Host "   Загрузка VSCode..." -ForegroundColor Yellow
    $vscInstaller = "$env:TEMP\vscode-installer.exe"
    try {
        $vscUrl = "https://code.visualstudio.com/sha/download?build=stable&os=win32-x64"
        Invoke-WebRequest -Uri $vscUrl -OutFile $vscInstaller
        
        # Тихая установка с необходимыми параметрами
        Start-Process -FilePath $vscInstaller -ArgumentList "/SILENT", "/MERGETASKS=!runcode" -Wait
        Write-Host "   Visual Studio Code успешно установлен" -ForegroundColor Green
        
        # Ждем регистрации в PATH
        Start-Sleep -Seconds 5
    }
    catch {
        Write-Error "   Ошибка при установке VSCode: $_"
    }
    finally {
        if (Test-Path $vscInstaller) {
            Remove-Item $vscInstaller
        }
    }
} else {
    Write-Host "   Visual Studio Code уже установлен" -ForegroundColor Yellow
}

# Установка расширения KiloCode для VSCode
Write-Host "`n7. Установка расширения KiloCode..." -ForegroundColor Cyan
Start-Sleep -Seconds 10  # Ожидание инициализации VSCode

try {
    & code --install-extension Kilo-Org.kilocode --force
    Write-Host "   Расширение KiloCode успешно установлено" -ForegroundColor Green
}
catch {
    Write-Host "   Предупреждение: Не удалось установить расширение автоматически. Установите вручную через Marketplace VSCode." -ForegroundColor Red
}

# Проверка структуры репозитория
Write-Host "`n8. Проверка структуры проекта..." -ForegroundColor Cyan
if (Test-Path "$InstallPath\README.md") {
    Write-Host "   Репозиторий KiloRAG успешно установлен" -ForegroundColor Green
    Write-Host "   Найдены файлы:" -ForegroundColor White
    Get-ChildItem -Path $InstallPath -Name | ForEach-Object { Write-Host "   - $_" -ForegroundColor White }
} else {
    Write-Host "   Внимание: Репозиторий не был скачан, создается базовая структура" -ForegroundColor Red
    Create-BaseStructure -InstallPath $InstallPath
}

# Функция для создания базовой структуры (как запасной вариант)
function Create-BaseStructure {
    param([string]$InstallPath)
    
    $folders = @(
        "БАЗА ЗНАНИЙ",
        "БАЗА ЗНАНИЙ\ДЛЯ ОТЛАДКИ", 
        "БАЗА ЗНАНИЙ\ДЛЯ ОТЛАДКИ\mcp-rules",
        "БАЗА ЗНАНИЙ\ДЛЯ ОТЛАДКИ\примеры",
        "исходные данные"
    )

    foreach ($folder in $folders) {
        $fullPath = Join-Path $InstallPath $folder
        if (!(Test-Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force
        }
    }

    # Создание базового README
    $readmeContent = @"
# KiloRAG: Система автоматизированного расчета категорий по пожарной и взрывопожарной опасности

Установка завершена автоматическим установщиком.

## Структура проекта:
- `исходные данные/` - поместите исходные файлы (docx, pdf, txt и др.)
- `промт.txt` - основной промт для запуска анализа  
- `БАЗА ЗНАНИЙ/` - база знаний системы

## Использование:
1. Загрузите исходные данные в папку 'исходные данные'
2. Отредактируйте при необходимости 'промт.txt'
3. Откройте проект в VSCode с установленным расширением KiloCode
4. Используйте символ @ в чате KiloCode для вызова промта

## Примечание:
Репозиторий не был скачан автоматически. Рекомендуется вручную скачать с https://github.com/firegoaway/KiloRAG
"@

    $readmeContent | Out-File -FilePath "$InstallPath\README.md" -Encoding UTF8
}

# Финальные инструкции
Write-Host "`n=== УСТАНОВКА ЗАВЕРШЕНА ===" -ForegroundColor Green
Write-Host "Что делать дальше:" -ForegroundColor Yellow
Write-Host "1. Откройте Visual Studio Code" -ForegroundColor White
Write-Host "2. Убедитесь, что расширение KiloCode установлено (иконка весов в боковой панели)" -ForegroundColor White
Write-Host "3. Откройте папку проекта: $InstallPath" -ForegroundColor White
Write-Host "4. Следуйте инструкциям в README.md проекта для использования системы" -ForegroundColor White

Write-Host "`nДля начала работы выполните:" -ForegroundColor Cyan
Write-Host "  code `"$InstallPath`"" -ForegroundColor White

# Проверка наличия файла методологии
if (Test-Path "$InstallPath\БАЗА ЗНАНИЙ\ДЛЯ ОТЛАДКИ\mcp-rules\Методология определения категорий.md") {
    Write-Host "`n✅ Файлы методологии найдены" -ForegroundColor Green
} else {
    Write-Host "`n⚠️  Файлы методологии отсутствуют. Скачайте репозиторий вручную." -ForegroundColor Red
}

# Открытие установочной директории
explorer $InstallPath