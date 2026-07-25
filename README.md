# Baixador de vídeos do YouTube

Interface gráfica simples para Windows que facilita o uso do `yt-dlp`, sem exigir que o usuário final digite comandos.

## Recursos

- Download de vídeo em MP4
- Extração de áudio em MP3
- Escolha da pasta de destino
- Verificação automática do `yt-dlp` e do FFmpeg
- Opção de instalação automática das dependências pelo `winget`
- Execução silenciosa, sem manter o Prompt de Comando aberto
- Interface e mensagens em PT-BR

## Como usar

1. Baixe os arquivos deste repositório e mantenha-os na mesma pasta.
2. Dê dois cliques em `Abrir-Baixador.vbs`.
3. Se o sistema detectar que `yt-dlp` ou FFmpeg não estão instalados, escolha **Sim** para permitir a instalação.
4. Cole um link do YouTube, escolha o formato e a pasta de destino.
5. Clique em **Baixar**.

O arquivo `Abrir-Baixador.cmd` é mantido apenas por compatibilidade. Para não exibir o Prompt de Comando, utilize o iniciador `.vbs`.

## Requisitos

- Windows 10 ou Windows 11
- Windows PowerShell 5.1 ou superior
- `winget` para instalação automática das dependências

## Uso responsável

Utilize o sistema somente para baixar conteúdo que você tenha autorização para acessar e armazenar, respeitando direitos autorais e os termos das plataformas.

## Créditos

Este sistema foi desenvolvido por **Paulo Sant anna** em **25/07/2026**, com o apoio do **Codex**.
