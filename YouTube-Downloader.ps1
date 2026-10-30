[CmdletBinding()]
param()

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

function Test-Program {
    param([Parameter(Mandatory)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Install-Dependency {
    param(
        [Parameter(Mandatory)][string]$DisplayName,
        [Parameter(Mandatory)][string]$PackageId,
        [Parameter(Mandatory)][string]$CommandName
    )

    if (Test-Program $CommandName) { return $true }

    $answer = [System.Windows.Forms.MessageBox]::Show(
        "$DisplayName não está instalado.`n`nDeseja instalá-lo automaticamente agora?",
        'Componente necessário', 'YesNo', 'Question'
    )
    if ($answer -ne 'Yes') { return $false }

    if (-not (Test-Program 'winget')) {
        [System.Windows.Forms.MessageBox]::Show(
            "O instalador de aplicativos do Windows (winget) não foi encontrado.`n`nInstale o componente Instalador de Aplicativo pela Microsoft Store e tente novamente.",
            'Instalação indisponível', 'OK', 'Error'
        )
        return $false
    }

    $statusLabel.Text = "Instalando $DisplayName... Aguarde."
    $statusLabel.ForeColor = [System.Drawing.Color]::DimGray
    $progress.Visible = $true
    $form.Refresh()

    try {
        $installProcess = Start-Process -FilePath 'winget.exe' -ArgumentList @(
            'install', '--id', $PackageId, '--exact',
            '--accept-package-agreements', '--accept-source-agreements', '--silent'
        ) -Wait -PassThru

        if ($installProcess.ExitCode -ne 0) {
            throw "O instalador terminou com o código $($installProcess.ExitCode)."
        }

        $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
        $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        $env:Path = "$machinePath;$userPath"

        if (Test-Program $CommandName) {
            [System.Windows.Forms.MessageBox]::Show(
                "$DisplayName foi instalado com sucesso.",
                'Instalação concluída', 'OK', 'Information'
            )
            return $true
        }

        [System.Windows.Forms.MessageBox]::Show(
            "$DisplayName foi instalado, mas ainda não está disponível nesta janela.`n`nFeche e abra novamente o baixador.",
            'Reinicialização necessária', 'OK', 'Information'
        )
        return $false
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Não foi possível instalar $DisplayName automaticamente.`n`nTente novamente ou faça a instalação manual.",
            'Falha na instalação', 'OK', 'Error'
        )
        return $false
    } finally {
        $progress.Visible = $false
    }
}

function Confirm-Dependencies {
    $ytDlpReady = Install-Dependency -DisplayName 'yt-dlp' -PackageId 'yt-dlp.yt-dlp' -CommandName 'yt-dlp'
    if (-not $ytDlpReady) {
        $statusLabel.Text = 'O yt-dlp é necessário para realizar downloads.'
        $statusLabel.ForeColor = [System.Drawing.Color]::Firebrick
        return $false
    }

    $ffmpegReady = Install-Dependency -DisplayName 'FFmpeg' -PackageId 'Gyan.FFmpeg' -CommandName 'ffmpeg'
    if (-not $ffmpegReady) {
        $statusLabel.Text = 'O FFmpeg é necessário para criar MP4 e MP3.'
        $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
        return $false
    }

    $statusLabel.Text = 'Tudo pronto: yt-dlp e FFmpeg estão instalados.'
    $statusLabel.ForeColor = [System.Drawing.Color]::ForestGreen
    return $true
}

function Get-DownloadHelp {
    param([string]$Details)

    if ($Details -match 'Sign in to confirm|cookies|bot') {
        return 'O YouTube solicitou autenticação. Abra o vídeo no navegador para confirmar que ele está disponível e tente novamente. Vídeos restritos podem exigir cookies de uma sessão conectada.'
    }
    if ($Details -match 'Video unavailable|Private video|members-only|age-restricted') {
        return 'O vídeo está indisponível, privado ou possui uma restrição que impede o download.'
    }
    if ($Details -match 'Unsupported URL|Invalid URL') {
        return 'O endereço informado não foi reconhecido como um vídeo válido do YouTube.'
    }
    if ($Details -match 'HTTP Error 403|HTTP Error 429|Too Many Requests') {
        return 'O YouTube recusou temporariamente a conexão. Aguarde alguns minutos, atualize o yt-dlp e tente novamente.'
    }
    if ($Details -match 'ffmpeg.*not found|Postprocessing') {
        return 'O download ocorreu, mas o FFmpeg não conseguiu processar o arquivo. Reinstale ou atualize o FFmpeg.'
    }
    if ($Details -match 'Unable to download|Temporary failure|timed out|connection') {
        return 'Não foi possível acessar o YouTube. Verifique a conexão, VPN, proxy ou firewall e tente novamente.'
    }

    return 'O yt-dlp não conseguiu concluir a operação. Atualize o programa e tente novamente.'
}

function Update-YtDlp {
    $statusLabel.Text = 'Atualizando o yt-dlp... Aguarde.'
    $statusLabel.ForeColor = [System.Drawing.Color]::DarkOrange
    $form.Refresh()

    $updateText = (& yt-dlp --update 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -eq 0) {
        return $true
    }

    if (Test-Program 'winget') {
        $updateProcess = Start-Process -FilePath 'winget.exe' -ArgumentList @(
            'upgrade', '--id', 'yt-dlp.yt-dlp', '--exact',
            '--accept-package-agreements', '--accept-source-agreements', '--silent'
        ) -Wait -PassThru
        return ($updateProcess.ExitCode -eq 0)
    }

    return $false
}

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Baixador de vídeos'
$form.Size = New-Object System.Drawing.Size(650, 430)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object System.Drawing.Font('Segoe UI', 10)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Baixar vídeo ou áudio'
$title.Font = New-Object System.Drawing.Font('Segoe UI Semibold', 17)
$title.AutoSize = $true
$title.Location = New-Object System.Drawing.Point(24, 20)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = 'Cole o endereço do vídeo, escolha o formato e clique em Baixar.'
$subtitle.AutoSize = $true
$subtitle.ForeColor = [System.Drawing.Color]::DimGray
$subtitle.Location = New-Object System.Drawing.Point(27, 58)
$form.Controls.Add($subtitle)

$urlLabel = New-Object System.Windows.Forms.Label
$urlLabel.Text = 'Link do YouTube'
$urlLabel.AutoSize = $true
$urlLabel.Location = New-Object System.Drawing.Point(27, 96)
$form.Controls.Add($urlLabel)

$urlBox = New-Object System.Windows.Forms.TextBox
$urlBox.Location = New-Object System.Drawing.Point(30, 120)
$urlBox.Size = New-Object System.Drawing.Size(580, 28)
$form.Controls.Add($urlBox)

$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Text = 'Formato'
$formatLabel.AutoSize = $true
$formatLabel.Location = New-Object System.Drawing.Point(27, 164)
$form.Controls.Add($formatLabel)

$formatBox = New-Object System.Windows.Forms.ComboBox
$formatBox.Location = New-Object System.Drawing.Point(30, 188)
$formatBox.Size = New-Object System.Drawing.Size(220, 28)
$formatBox.DropDownStyle = 'DropDownList'
[void]$formatBox.Items.Add('Vídeo MP4 (melhor qualidade)')
[void]$formatBox.Items.Add('Áudio MP3')
$formatBox.SelectedIndex = 0
$form.Controls.Add($formatBox)

$folderLabel = New-Object System.Windows.Forms.Label
$folderLabel.Text = 'Salvar em'
$folderLabel.AutoSize = $true
$folderLabel.Location = New-Object System.Drawing.Point(267, 164)
$form.Controls.Add($folderLabel)

$folderBox = New-Object System.Windows.Forms.TextBox
$folderBox.Location = New-Object System.Drawing.Point(270, 188)
$folderBox.Size = New-Object System.Drawing.Size(270, 28)
$folderBox.Text = [Environment]::GetFolderPath('MyVideos')
$form.Controls.Add($folderBox)

$browseButton = New-Object System.Windows.Forms.Button
$browseButton.Text = '...'
$browseButton.Location = New-Object System.Drawing.Point(550, 187)
$browseButton.Size = New-Object System.Drawing.Size(60, 30)
$form.Controls.Add($browseButton)

$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(30, 246)
$progress.Size = New-Object System.Drawing.Size(580, 18)
$progress.Style = 'Marquee'
$progress.Visible = $false
$form.Controls.Add($progress)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Pronto para baixar.'
$statusLabel.AutoSize = $false
$statusLabel.Location = New-Object System.Drawing.Point(30, 276)
$statusLabel.Size = New-Object System.Drawing.Size(580, 45)
$statusLabel.ForeColor = [System.Drawing.Color]::DimGray
$form.Controls.Add($statusLabel)

$openButton = New-Object System.Windows.Forms.Button
$openButton.Text = 'Abrir pasta'
$openButton.Location = New-Object System.Drawing.Point(384, 333)
$openButton.Size = New-Object System.Drawing.Size(105, 36)
$form.Controls.Add($openButton)

$downloadButton = New-Object System.Windows.Forms.Button
$downloadButton.Text = 'Baixar'
$downloadButton.Location = New-Object System.Drawing.Point(500, 333)
$downloadButton.Size = New-Object System.Drawing.Size(110, 36)
$downloadButton.BackColor = [System.Drawing.Color]::FromArgb(20, 105, 190)
$downloadButton.ForeColor = [System.Drawing.Color]::White
$downloadButton.FlatStyle = 'Flat'
$form.AcceptButton = $downloadButton
$form.Controls.Add($downloadButton)

$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
$folderDialog.Description = 'Escolha onde salvar o arquivo'

$form.Add_Shown({
    $form.Activate()
    [void](Confirm-Dependencies)
})

$browseButton.Add_Click({
    if ($folderDialog.ShowDialog() -eq 'OK') {
        $folderBox.Text = $folderDialog.SelectedPath
    }
})

$openButton.Add_Click({
    $target = $folderBox.Text.Trim()
    if (Test-Path -LiteralPath $target -PathType Container) {
        Start-Process explorer.exe -ArgumentList "`"$target`""
    } else {
        [System.Windows.Forms.MessageBox]::Show(
            'A pasta escolhida ainda não existe.', 'Pasta não encontrada', 'OK', 'Information'
        )
    }
})

$downloadButton.Add_Click({
    $url = $urlBox.Text.Trim()
    $destination = $folderBox.Text.Trim()

    if ($url -notmatch '^https?://(www\.)?(youtube\.com|youtu\.be)/') {
        [System.Windows.Forms.MessageBox]::Show(
            'Cole um link válido do YouTube.', 'Link inválido', 'OK', 'Warning'
        )
        return
    }

    if (-not (Confirm-Dependencies)) { return }

    if (-not (Test-Path -LiteralPath $destination -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $destination -Force -ErrorAction Stop | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                'Não foi possível criar a pasta de destino.', 'Erro', 'OK', 'Error'
            )
            return
        }
    }

    $outputTemplate = Join-Path $destination '%(title)s [%(id)s].%(ext)s'
    if ($formatBox.SelectedIndex -eq 1) {
        $arguments = @(
            '--no-playlist', '--newline', '-x', '--audio-format', 'mp3',
            '--audio-quality', '0', '-o', $outputTemplate, $url
        )
    } else {
        $arguments = @(
            '--no-playlist', '--newline', '-f', 'bv*+ba/b',
            '--merge-output-format', 'mp4', '-o', $outputTemplate, $url
        )
    }

    $downloadButton.Enabled = $false
    $browseButton.Enabled = $false
    $formatBox.Enabled = $false
    $progress.Visible = $true
    $statusLabel.ForeColor = [System.Drawing.Color]::DimGray
    $statusLabel.Text = 'Baixando... Aguarde; isso pode levar alguns minutos.'
    $form.Refresh()

    try {
        $downloadText = (& yt-dlp @arguments 2>&1 | Out-String).Trim()
        $downloadExitCode = $LASTEXITCODE

        $shouldUpdate = $downloadExitCode -ne 0 -and (
            $downloadText -match 'older than 90 days|latest version|update yt-dlp|HTTP Error 403'
        )

        if ($shouldUpdate) {
            if (Update-YtDlp) {
                $statusLabel.Text = 'Atualização concluída. Tentando o download novamente...'
                $statusLabel.ForeColor = [System.Drawing.Color]::DimGray
                $form.Refresh()
                $downloadText = (& yt-dlp @arguments 2>&1 | Out-String).Trim()
                $downloadExitCode = $LASTEXITCODE
            } else {
                $downloadText += "`nNão foi possível atualizar o yt-dlp automaticamente."
            }
        }

        if ($downloadExitCode -eq 0) {
            $statusLabel.ForeColor = [System.Drawing.Color]::ForestGreen
            $statusLabel.Text = 'Download concluído com sucesso.'
            [System.Windows.Forms.MessageBox]::Show(
                'O arquivo foi baixado com sucesso.', 'Concluído', 'OK', 'Information'
            )
        } else {
            $friendlyHelp = Get-DownloadHelp -Details $downloadText
            $technicalDetails = $downloadText
            if ($technicalDetails.Length -gt 900) {
                $technicalDetails = $technicalDetails.Substring($technicalDetails.Length - 900)
            }
            throw "$friendlyHelp`n`nDetalhes técnicos:`n$technicalDetails"
        }
    } catch {
        $statusLabel.ForeColor = [System.Drawing.Color]::Firebrick
        $statusLabel.Text = 'Não foi possível concluir o download.'
        [System.Windows.Forms.MessageBox]::Show(
            "O download falhou.`n`n$($_.Exception.Message)",
            'Falha no download', 'OK', 'Error'
        )
    } finally {
        $progress.Visible = $false
        $downloadButton.Enabled = $true
        $browseButton.Enabled = $true
        $formatBox.Enabled = $true
    }
})

[void]$form.ShowDialog()

