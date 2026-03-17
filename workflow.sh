#!/bin/bash
set -e # Exit on any error

# Random sleep between 1 and 300 seconds to avoid collisions
sleep $((RANDOM % 300 + 1))

# Set git user identity
git config user.name "PkLavc"
git config user.email "patrickajm@gmail.com"

# Skip if there are no real changes to commit
if git diff --exit-code history.json index.html uptime-badge.json assets/; then
    echo "No changes detected. Skipping merge."
    exit 0
fi

BRANCH="sre-dashboard-$(date +%Y%m%d-%H%M%S)"
git checkout -b $BRANCH

git add .

# Commit message options (randomized)
MESSAGES=(
    "metrics: update dashboard"
    "stats: sync uptime data"
    "ci: refresh reliability metrics"
    "monitor: update service status"
    "sre: dashboard metrics refresh"
)

ALERT_MESSAGES=(
    "alert: performance degradation detected"
    "alert: significant page size change detected"
    "alert: service disruption detected"
)

# Choose commit message based on monitor.py exit code
if [ "${MONITOR_EXIT_CODE:-0}" -eq 1 ]; then
    RANDOM_INDEX=$((RANDOM % ${#ALERT_MESSAGES[@]}))
    COMMIT_MSG="${ALERT_MESSAGES[$RANDOM_INDEX]}"
else
    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    COMMIT_MSG="${MESSAGES[$RANDOM_INDEX]}"
fi

git commit -m "$COMMIT_MSG" -m "Co-authored-by: pklavc-labs <modderkcaheua@gmail.com>"

# Ensure the branch is up to date before pushing
git fetch origin
git rebase origin/main

git push origin $BRANCH --force

# Create and merge PR with professional metadata
if [ "${MONITOR_EXIT_CODE:-0}" -eq 1 ]; then
    PR_TITLE="🔴 Inteligência GTA VI: Atualização Detectada - $(date +'%Y-%m-%d %H:%M')"
else
    PR_TITLE="🟢 Vigilância Rockstar: Sistema Monitorado - $(date +'%Y-%m-%d %H:%M')"
fi

PR_URL=$(gh pr create --title "$PR_TITLE" \
                      --body "Atualização automática de monitoramento de inteligência em tempo real sobre GTA VI.

**Mudanças:**
- Histórico de vigilância atualizado em history.json
- Visualizações do dashboard atualizadas em index.html
- Novos dados de detecção de atualização e análise de conteúdo
- Badge de status atualizado com dados mais recentes

**Serviços Monitorados:**
- GTA VI Official (https://www.rockstargames.com/VI/)
- Rockstar Newswire (https://www.rockstargames.com/br/newswire)
- PlayStation Store (https://www.playstation.com/pt-br/games/grand-theft-auto-vi/)
- Xbox Store (https://www.xbox.com/pt-PT/games/store/grand-theft-auto-vi/)

**Recursos de Inteligência:**
- Detecção de atualizações por SHA-256
- Análise de tamanho de conteúdo em tempo real
- Métricas de disponibilidade (24h, 7d, 30d)
- Análise de latência (DNS, TCP, Transfer)
- Histórico de incidentes
- Verificação de headers de segurança

**Dashboard:** [index.html](./index.html)" \
                      --base main --head $BRANCH --fill)

echo "Merging PR: $PR_URL"
gh pr merge "$PR_URL" --merge --delete-branch --admin
