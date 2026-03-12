# SRE Dashboard - Uptime Monitor System

## Current Status

![Online](https://img.shields.io/badge/Status-ONLINE-brightgreen)

**Last Check:** 2026-03-12 17:37:31  
**URL:** https://pklavc.github.io/  
**Status:** ONLINE  
**Latency:** 732.86ms  
**Average Latency (last 20):** 732.86ms  
**Total Checks:** 1

---

## Visão Geral

Este é um sistema automatizado de monitoramento de disponibilidade (uptime) que verifica periodicamente o status de serviços web e registra os resultados em um repositório Git. O sistema cria automaticamente Pull Requests e realiza merges para atualizar o histórico de monitoramento, utilizando uma abordagem GitOps para fornecer uma página de status serverless e auditável publicamente.

## Funcionamento do Sistema

O sistema funciona em 4 etapas principais:

1. **Monitoramento**: O script `monitor.py` faz requisições HTTP aos serviços monitorados e registra o status, latência e métricas de performance
2. **Armazenamento**: Os resultados são salvos no arquivo `history.json` com rotação de logs (máx 500 registros)
3. **Dashboard**: O script atualiza automaticamente o dashboard interativo em `index.html` com gráficos em tempo real
4. **Atualização do Repositório**: O script `workflow.sh` cria branches, commita as alterações e realiza merge automático via GitHub Actions

## Arquitetura do Sistema

```
uptime-monitor/
├── monitor.py              # Script de monitoramento principal
├── workflow.sh             # Script de automação Git com variabilidade
├── index.html              # Dashboard interativo com gráficos Chart.js
├── assets/
│   ├── style.css           # Estilos CSS modulares
│   └── script.js           # Lógica JavaScript do dashboard
├── history.json            # Histórico de monitoramento em JSON
├── uptime-badge.json       # Badge do Shields.io
├── data/status.json        # Dados legados (compatibilidade)
└── README.md              # Documentação e status atual
```

## Funcionalidades

### Monitoramento Avançado
- **Métricas de Performance**: DNS, TCP, Transfer times
- **SLA Calculation**: Disponibilidade 24h, 7d, 30d
- **Health Checks**: Verificação de conteúdo e headers de segurança
- **Page Size Monitoring**: Auditoria de performance do codepulse-monorepo
- **Incident Tracking**: Log automático de incidentes

### Dashboard Interativo
- **Gráficos em Tempo Real**: Uptime, latência e tamanho de página
- **Status Cards**: Status atual e métricas por serviço
- **Responsive Design**: Otimizado para desktop e mobile
- **Dark Theme**: Interface moderna com tema escuro

### GitOps Automation
- **Pull Requests Automáticas**: Commits regulares com mensagens variadas
- **Sleep Aleatório**: Evita padrões previsíveis (1-300s)
- **Alert System**: Commits especiais para incidentes
- **Serverless**: 100% hospedado no GitHub Pages

## Instalação e Uso

### Pré-requisitos
- Python 3.8+
- Git
- GitHub CLI (gh)

### Configuração
1. Clone o repositório
2. Instale dependências: `pip install requests`
3. Configure Git user: `git config user.name "Seu Nome"`
4. Execute o monitoramento: `python monitor.py`

### GitHub Actions
O sistema é projetado para rodar automaticamente via GitHub Actions com workflow de CI/CD integrado.

## FAQ

### Why so many commits?
"This project uses a GitOps approach for real-time monitoring. Instead of hosting a database, we use the repository as a time-series data store to provide a 100% serverless status page. This allows for transparent, public-auditability of our service uptime and performance metrics."

### How does the dashboard work?
The dashboard is a static HTML page with embedded Chart.js graphs. The `monitor.py` script injects JSON data directly into the HTML, which is then read by the JavaScript to render real-time charts and metrics.

### What services are monitored?
- **GitHub Pages**: Main website uptime and performance
- **GitHub API**: Repository metrics and engagement data
- **CodePulse Monorepo**: Page size auditing for performance monitoring

### How is uptime calculated?
Uptime percentages are calculated based on successful HTTP responses. For new services with limited history, the system assumes 100% uptime if the current check is successful (Initial State Logic).

## Desenvolvimento

### Estrutura de Arquivos
- `monitor.py`: Core monitoring logic with advanced metrics
- `assets/script.js`: Dashboard JavaScript with Chart.js integration
- `assets/style.css`: Modular CSS with dark theme
- `workflow.sh`: Git automation with randomized commits
- `index.html`: Static dashboard template

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## Licença

Este projeto está licenciado sob a MIT License - veja o arquivo [LICENSE](LICENSE) para detalhes.
        
    except Exception as e:
        record = {
            "timestamp": datetime.datetime.now().isoformat(),
            "url": URL,
            "status": "ERROR",
            "latency_ms": 0,
            "error": str(e)
        }
    
    # Adiciona o novo registro
    data["records"].append(record)
    data["monitoring"]["total_checks"] += 1
    
    # Implementa log rotation (mantém apenas os últimos 100 registros)
    if len(data["records"]) > MAX_RECORDS:
        data["records"] = data["records"][-MAX_RECORDS:]
    
    save_status_data(data)
    return record

def calculate_average_latency(data, limit=20):
    """Calcula a latência média dos últimos registros"""
    online_records = [r for r in data["records"] if r.get("status") == "ONLINE" and r.get("latency_ms", 0) > 0]
    if not online_records:
        return 0
    
    recent_records = online_records[-limit:] if len(online_records) >= limit else online_records
    return sum(r["latency_ms"] for r in recent_records) / len(recent_records)

def get_latency_trend(data, last_n=5):
    """Verifica a tendência de latência nas últimas N verificações"""
    online_records = [r for r in data["records"] if r.get("status") == "ONLINE" and r.get("latency_ms", 0) > 0]
    if len(online_records) < last_n + 1:
        return None, 0
    
    recent = online_records[-last_n:]
    older = online_records[-(last_n*2):-last_n]
    
    recent_avg = sum(r["latency_ms"] for r in recent) / len(recent)
    older_avg = sum(r["latency_ms"] for r in older) / len(older)
    
    change_percent = ((recent_avg - older_avg) / older_avg) * 100 if older_avg > 0 else 0
    
    return recent_avg, change_percent

def update_readme_status():
    """Atualiza a seção 'Current Status' no README.md"""
    data = load_status_data()
    
    if not data["records"]:
        return
    
    # Obtém o último registro
    last_record = data["records"][-1]
    current_status = last_record["status"]
    
    # Calcula latência média
    avg_latency = calculate_average_latency(data)
    
    # Determina a badge de status
    if current_status == "ONLINE":
        status_badge = "![Online](https://img.shields.io/badge/Status-ONLINE-brightgreen)"
    elif current_status == "ERROR":
        status_badge = "![Error](https://img.shields.io/badge/Status-ERROR-orange)"
    else:
        status_badge = "![Offline](https://img.shields.io/badge/Status-OFFLINE-red)"
    
    # Formata o timestamp
    last_check_time = datetime.datetime.fromisoformat(last_record["timestamp"]).strftime("%Y-%m-%d %H:%M:%S")
    
    # Cria a seção de status
    status_section = f"""## Current Status

{status_badge}

**Last Check:** {last_check_time}  
**URL:** {URL}  
**Status:** {current_status}  
**Latency:** {last_record.get('latency_ms', 0)}ms  
**Average Latency (last 20):** {avg_latency:.2f}ms  
**Total Checks:** {data['monitoring']['total_checks']}

---

"""
    
    # Lê o README atual
    try:
        with open("README.md", 'r') as f:
            readme_content = f.read()
    except FileNotFoundError:
        readme_content = "# Uptime Monitor System\n\n"
    
    # Remove a seção existente de Current Status se houver
    if "## Current Status" in readme_content:
        lines = readme_content.split('\n')
        new_lines = []
        skip = False
        for line in lines:
            if line.strip() == "## Current Status":
                skip = True
                continue
            elif skip and line.startswith("## "):
                skip = False
                new_lines.append(line)
            elif not skip:
                new_lines.append(line)
        readme_content = '\n'.join(new_lines)
    
    # Insere a nova seção logo após o cabeçalho principal
    if "# Uptime Monitor System" in readme_content:
        parts = readme_content.split("# Uptime Monitor System\n\n", 1)
        if len(parts) > 1:
            readme_content = parts[0] + "# Uptime Monitor System\n\n" + status_section + parts[1]
        else:
            readme_content = "# Uptime Monitor System\n\n" + status_section + parts[0]
    else:
        readme_content = "# Uptime Monitor System\n\n" + status_section + readme_content
    
    # Salva o README atualizado
    with open("README.md", 'w') as f:
        f.write(readme_content)

def should_alert_latency(data):
    """Verifica se deve gerar alerta de latência"""
    _, change_percent = get_latency_trend(data)
    return change_percent > 20 if change_percent is not None else False

def create_alert_flag():
    """Cria um arquivo de alerta para ser detectado pelo workflow.sh"""
    with open("ALERT_FLAG", "w") as f:
        f.write("Latency spike detected at " + datetime.datetime.now().isoformat())

if __name__ == "__main__":
    # Executa o monitoramento
    record = check()
    
    # Atualiza o README
    update_readme_status()
    
    # Verifica necessidade de alerta de latência
    data = load_status_data()
    if should_alert_latency(data):
        print("ALERT: Latency spike detected!")
        create_alert_flag()
        sys.exit(1)  # Indica alerta para o workflow
    else:
        print("Monitoramento concluído com sucesso")
        sys.exit(0)
```

### workflow.sh (Versão Atualizada)

```bash
#!/bin/bash
set -e # Para o script se qualquer comando falhar

# Identidade USA Standard para atribuição de conquistas
git config user.name "PkLavc"
git config user.email "patrickajm@gmail.com"

# Verifica se houve mudança real no log antes de criar PR
if git diff --exit-code data/status.json README.md; then
    echo "Nenhuma mudança detectada. Pulando merge."
    exit 0
fi

BRANCH="status-update-$(date +%Y%m%d-%H%M)"
git checkout -b $BRANCH

git add data/status.json README.md

# Determina a mensagem de commit baseada nos resultados
if [ -f "ALERT_FLAG" ]; then
    git commit -m "performance: latency spike detected

Automated uptime check detected significant latency increase.
Last check: $(tail -1 data/status.json | jq -r '.timestamp')
Status: $(tail -1 data/status.json | jq -r '.status')"
    rm -f ALERT_FLAG
else
    git commit -m "data: update uptime metrics and status dashboard

Automated uptime check completed successfully.
Last check: $(tail -1 data/status.json | jq -r '.timestamp')
Status: $(tail -1 data/status.json | jq -r '.status')"
fi

git push origin $BRANCH --force

# Criar e Mesclar PR com metadados profissionais
PR_URL=$(gh pr create --title "📈 System Metrics: $(date +'%Y-%m-%d %H:%M')" \
                      --body "Automated uptime check and dashboard synchronization.

**Changes:**
- Updated uptime metrics in data/status.json
- Refreshed status dashboard in README.md

**Last Check:** $(tail -1 data/status.json | jq -r '.timestamp')
**Status:** $(tail -1 data/status.json | jq -r '.status')
**Latency:** $(tail -1 data/status.json | jq -r '.latency_ms')ms" \
                      --base main --head $BRANCH)

gh pr merge "$PR_URL" --merge --delete-branch --admin
```

### .github/workflows/uptime.yml

```yaml
name: Uptime Monitor

on:
  schedule:
    # Executa a cada 60 minutos
    - cron: "0 * * * *"
  workflow_dispatch:

jobs:
  uptime-monitor:
    runs-on: ubuntu-latest
    permissions:
      contents: write
      pull-requests: write
      actions: read
    
    steps:
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