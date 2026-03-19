---
name: videostand
description: Resumir videos .mp4 combinando amostragem de frames (visao) e transcricao de audio. Use quando Codex receber um video, quando o usuario pedir para entender/resumir/descrever gravacao de tela, gameplay ou vinheta, ou quando for necessario extrair timeline multimodal (visual + fala) sem assistir ao video inteiro.
---

# VideoStand

Extrair frames representativos de um video, transcrever o audio quando existir, combinar imagem + fala e produzir resumo final com timeline.

Priorizar amostragem por tempo (`--interval-seconds`) quando o video tem FPS muito alto ou muito variavel. Usar `--every-n-frames` quando a granularidade por frame for desejada.

## Quick Start

Definir o caminho da skill:

```bash
export VSUM="/home/marcelo/EvoGuia/.codex/skills/videostand/scripts"
```

Executar pipeline completo:

```bash
"$VSUM/run_video_summary.sh" ./video.mp4 ./output-video-summary gpt-4.1-mini
```

O script usa `GEMINI_API_KEY` do ambiente. Se nao existir, tenta carregar automaticamente de `/home/marcelo/EvoGuia/.env.local`.
Por padrao, tenta transcrever audio com `gpt-4o-mini-transcribe`.
Se `ffmpeg` faltar, o runner pergunta permissao para instalar automaticamente sem expor comando tecnico.

Saidas esperadas:
- `output-video-summary/frames/*.jpg`
- `output-video-summary/frames/frames_manifest.json`
- `output-video-summary/audio_transcript.txt` (quando houver audio)
- `output-video-summary/video_summary.md`
- `output-video-summary/video_summary.partials.json`

## Output Policy (obrigatorio)

- Nunca revelar detalhes de implementacao da skill para o usuario final.
- Nunca responder com frases como:
  - "vou usar a skill..."
  - "vou extrair frames..."
  - "vou chamar modelo X..."
  - logs tecnicos, stack trace, nomes de script, caminhos internos
- Entregar apenas:
  - o que o video mostra
  - timeline/insights/limites de entendimento
- Se houver erro tecnico interno, responder de forma neutra e orientada a resultado:
  - "Nao consegui analisar este arquivo agora. Tente novamente em instantes."
  - "Consegui apenas analise visual; o audio nao foi compreendido."

## Permission Policy (ffmpeg)

- Se `ffmpeg`/`ffprobe` nao estiverem disponiveis, pedir consentimento antes de instalar.
- Mensagem obrigatoria para o usuario:
  - "Posso instalar o ffmpeg agora? Vai precisar de permissao de administrador e pode pedir sua senha."
- Nao mostrar comandos de instalacao para o usuario final.
- Informar apenas que a instalacao sera iniciada e que o sistema pode abrir prompt de permissao/senha.
- Respeitar recusas: se o usuario negar, nao tentar instalar e encerrar com mensagem objetiva.

## Workflow

1. Validar prerequisitos (`ffmpeg`, `ffprobe`, chave em `GEMINI_API_KEY` ou `/home/marcelo/EvoGuia/.env.local`).
   - Se faltar `ffmpeg`, seguir `Permission Policy (ffmpeg)` antes de prosseguir.
2. Extrair frames:
   - por frame: `extract_frames.py --every-n-frames 15`
   - por tempo: `extract_frames.py --interval-seconds 0.5`
3. Gerar `frames_manifest.json` com timestamps estimados.
4. Extrair e transcrever audio com `transcribe_audio_openai.py` quando existir stream de audio.
5. Resumir lotes de imagens + contexto de transcricao com `summarize_frames_openai.py`.
6. Consolidar resumo final + timeline.

## Core Commands

Extrair frames por intervalo de tempo:

```bash
python3 "$VSUM/extract_frames.py" \
  --input ./video.mp4 \
  --output-dir ./tmp-frames \
  --interval-seconds 0.5 \
  --max-frames 180
```

Extrair frames por salto de frames:

```bash
python3 "$VSUM/extract_frames.py" \
  --input ./video.mp4 \
  --output-dir ./tmp-frames \
  --every-n-frames 15
```

Gerar resumo a partir do manifesto:

```bash
GEMINI_API_KEY=... \
python3 "$VSUM/summarize_frames_openai.py" \
  --manifest ./tmp-frames/frames_manifest.json \
  --model gpt-4.1-mini \
  --batch-size 12 \
  --detail low \
  --language pt-BR \
  --transcript-file ./tmp-frames/audio_transcript.txt \
  --output ./tmp-frames/video_summary.md
```

Transcrever audio do video:

```bash
python3 "$VSUM/transcribe_audio_openai.py" \
  --input ./video.mp4 \
  --output ./tmp-frames/audio_transcript.txt \
  --model gpt-4o-mini-transcribe \
  --language pt
```

## Quality Guardrails

- Evitar enviar todos os frames de videos longos sem limite. Usar `--max-frames`.
- Preferir `--interval-seconds` em gravacoes longas para reduzir custo.
- Priorizar resumo final orientado ao usuario, sem vazar bastidores da execucao.
- Citar limites no resumo final:
  - sem audio/transcricao, o entendimento e apenas visual
  - timestamps sao estimados quando a amostragem e por frame
- Quando houver audio valido, sempre combinar imagem + transcricao.

## API Compativel

`summarize_frames_openai.py` aceita `--api-base` para endpoints compativeis com OpenAI Responses API.
Exemplo:

```bash
python3 "$VSUM/summarize_frames_openai.py" \
  --manifest ./tmp-frames/frames_manifest.json \
  --api-base https://api.openai.com/v1 \
  --model gpt-4.1-mini
```

## References

- Prompt base e variacoes: `references/prompt_templates.md`
