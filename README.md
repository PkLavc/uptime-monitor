# SRE Dashboard - Uptime Monitor System

## Overview

This repository implements an automated uptime monitoring system that periodically checks critical services and updates a GitHub-hosted status dashboard.

## What It Does

- Runs scheduled HTTP checks against configured endpoints
- Tracks uptime, latency, and performance metrics
- Stores monitoring history in `history.json`
- Automatically creates and merges PRs to keep the dashboard up to date
- Displays real-time charts via a static `index.html` dashboard

## Project Structure

```
uptime-monitor/
├── monitor.py              # Main monitoring script (checks + dashboard injection)
├── workflow.sh             # Helper script to run the full workflow locally
├── .github/workflows/      # GitHub Actions workflows (scheduled runs + PR automation)
├── index.html              # Static dashboard template
├── assets/
│   ├── style.css           # Dashboard styling
│   └── script.js           # Dashboard charting logic
├── history.json            # Stored monitoring history
├── uptime-badge.json       # Shields.io badge configuration
└── README.md               # Documentation (this file)
```

## How It Works

1. `monitor.py` checks endpoints and records results.
2. It injects the latest JSON data into `index.html` so the dashboard updates without a backend.
3. GitHub Actions runs the monitor periodically, commits changes, and opens/merges a PR using a PAT.

## Getting Started

### Requirements

- Python 3.8+
- Git
- (Optional) GitHub CLI (`gh`) for local workflow testing

### Run Locally

```sh
pip install requests
python monitor.py
```

## GitHub Actions

The workflow uses a Personal Access Token (`PAT_SHARK`) stored as a repository secret to create and merge PRs under your user account.

## License

MIT License — see [LICENSE](LICENSE) for details.

      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Necessário para git diff
        
      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.x'
        
      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install requests
          
      - name: Run uptime check
        id: monitor
        run: |
          python monitor.py
          echo "MONITOR_EXIT_CODE=$?" >> $GITHUB_ENV
          
      - name: Check for changes
        id: changes
        run: |
          if git diff --exit-code data/status.json README.md; then
            echo "CHANGES=false" >> $GITHUB_OUTPUT
          else
            echo "CHANGES=true" >> $GITHUB_OUTPUT
          fi
          
      - name: Create branch and commit
        if: steps.changes.outputs.CHANGES == 'true'
        run: |
          git config user.name "PkLavc"
          git config user.email "patrickajm@gmail.com"
          
          BRANCH="status-update-$(date +%Y%m%d-%H%M)"
          git checkout -b $BRANCH
          
          git add data/status.json README.md
          
          # Determina a mensagem de commit baseada nos resultados
          if [ "$MONITOR_EXIT_CODE" -eq 1 ]; then
            git commit -m "performance: latency spike detected
          
          Automated uptime check detected significant latency increase.
          Last check: $(tail -1 data/status.json | jq -r '.timestamp')
          Status: $(tail -1 data/status.json | jq -r '.status')"
          else
            git commit -m "data: update uptime metrics and status dashboard
          
          Automated uptime check completed successfully.
          Last check: $(tail -1 data/status.json | jq -r '.timestamp')
          Status: $(tail -1 data/status.json | jq -r '.status')"
          fi
          
          git push origin $BRANCH --force
          
      - name: Create and merge PR
        if: steps.changes.outputs.CHANGES == 'true'
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          BRANCH="status-update-$(date +%Y%m%d-%H%M)"
          
          echo "Creating PR..."
          PR_URL=$(gh pr create --title "📈 System Metrics: $(date +'%Y-%m-%d %H:%M')" \
                               --body "Automated uptime check and dashboard synchronization.

          **Changes:**
          - Updated uptime metrics in data/status.json
          - Refreshed status dashboard in README.md
          
          **Last Check:** $(tail -1 data/status.json | jq -r '.timestamp')
          **Status:** $(tail -1 data/status.json | jq -r '.status')
          **Latency:** $(tail -1 data/status.json | jq -r '.latency_ms')ms" \
                               --base main --head $BRANCH)
          
          echo "Merging PR: $PR_URL"
          gh pr merge "$PR_URL" --merge --delete-branch --admin
```

### data/status.json (Exemplo de Estrutura)

```json
{
  "monitoring": {
    "url": "https://pklavc.github.io/",
    "created_at": "2026-03-12T17:37:30.742584",
    "total_checks": 1
  },
  "records": [
    {
      "timestamp": "2026-03-12T17:37:31.475478",
      "url": "https://pklavc.github.io/",
      "status": "ONLINE",
      "latency_ms": 732.86,
      "http_code": 200
    }
  ]
}
```

## Como Funciona o "Merge de Ping"

O sistema implementa um fluxo automatizado de CI/CD que:

1. **Cria Branch Temporário**: Gera um branch com timestamp (`status-update-YYYYMMDD-HHMM`)
2. **Realiza Commit**: Adiciona as alterações do `data/status.json` e `README.md` e cria um commit
3. **Push para o Remote**: Envia o branch para o repositório remoto
4. **Cria Pull Request**: Usa o GitHub CLI (`gh pr create`) para criar um PR automático
5. **Merge Automático**: Realiza o merge do PR usando `gh pr merge` com administração

### Novas Funcionalidades Implementadas

#### 1. Armazenamento em JSON
- **Arquivo**: `data/status.json`
- **Estrutura**: Dados estruturados com metadados de monitoramento
- **Rotação**: Mantém apenas os últimos 100 registros para evitar crescimento infinito

#### 2. Dashboard Automático no README
- **Seção**: "Current Status" atualizada automaticamente
- **Informações**: Status em tempo real, latência média, badge de status
- **Atualização**: Sempre que o monitoramento é executado

#### 3. Detecção de Spikes de Latência
- **Comparação**: Média das últimas 5 verificações vs 5 verificações anteriores
- **Alerta**: Se latência subir mais de 20%, gera alerta
- **Commit**: Mensagem de commit inclui "performance: latency spike detected"

#### 4. Workflow do GitHub Actions
- **Agendamento**: Executa a cada 60 minutos
- **Automação**: Executa monitor.py e workflow.sh automaticamente
- **Autenticação**: Usa GITHUB_TOKEN para operações Git

#### 5. Verificação Inteligente de Mudanças
- **Git Diff**: Verifica se houve mudanças reais antes de criar PR
- **Evita Loops**: Impede commits vazios e loops infinitos
- **Eficiência**: Pula merge quando não há alterações

#### 6. Mensagens de Commit Dinâmicas
- **Baseado em Resultado**: Mensagem varia conforme o resultado do monitoramento
- **Alertas de Performance**: Mensagens específicas para spikes de latência
- **Metadados**: Inclui informações de status e latência nas mensagens

## Configuração Necessária

### Dependências

- Python 3.x
- Biblioteca `requests` para Python
- Git configurado
- GitHub CLI (`gh`) instalado e autenticado

### Instalação das Dependências

```bash
# Instalar requests para Python
pip install requests

# Instalar GitHub CLI (se necessário)
# Para Windows: https://cli.github.com/
# Para Linux: apt install gh
# Para macOS: brew install gh
```

### Configuração do Git

```bash
git config user.name "PkLavc"
git config user.email "patrickajm@gmail.com"
```

### Autenticação do GitHub CLI

```bash
gh auth login
```

## Uso

### Execução Manual

```bash
# Executar o monitoramento
python monitor.py

# Executar o workflow de atualização
bash workflow.sh
```

### Automatização com Cron

Para monitoramento contínuo, configure um cron job:

```bash
# Editar crontab
crontab -e

# Adicionar entradas (exemplo: a cada 5 minutos)
*/5 * * * * cd /caminho/para/uptime-monitor && python monitor.py && bash workflow.sh
```

## Estrutura do Log

Cada entrada no `uptime_log.txt` contém:

- **Timestamp**: Data e hora do monitoramento
- **URL**: Endereço do site monitorado
- **Status**: ONLINE/OFFLINE ou código de erro HTTP
- **Latência**: Tempo de resposta em milissegundos

Formato: `[YYYY-MM-DD HH:MM:SS] URL | STATUS | LATENCIAms`

## Segurança

- O script usa timeout de 10 segundos para evitar bloqueios
- Trata exceções para garantir registro mesmo em falhas de conexão
- Usa branchs temporários para evitar conflitos no main
- Realiza merge automático apenas após criação do PR

## Monitoramento

O site monitorado é: **https://pklavc.github.io/**

O sistema verifica:
- Disponibilidade HTTP (código 200 = ONLINE)
- Tempo de resposta (latência)
- Erros de conexão e timeout

## Licença

MIT License - Veja o arquivo LICENSE para detalhes.

## Contribuição

Para contribuir com melhorias:

1. Faça fork do repositório
2. Crie um branch (`git checkout -b feature/nome-da-feature`)
3. Commit suas mudanças (`git commit -m 'Add some feature'`)
4. Push para o branch (`git push origin feature/nome-da-feature`)
5. Abra um Pull Request

## Contato

Patrick Araujo | Software Engineer
- Email: patrickajm@gmail.com
- GitHub: [PkLavc](https://github.com/PkLavc)