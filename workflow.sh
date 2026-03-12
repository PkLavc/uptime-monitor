#!/bin/bash
set -e # Para o script se qualquer comando falhar

# Identidade USA Standard para atribuição de conquistas
git config user.name "PkLavc"
git config user.email "patrickajm@gmail.com"

# Verifica se houve mudança real antes de criar PR
if git diff --exit-code history.json index.html uptime-badge.json; then
    echo "Nenhuma mudança detectada. Pulando merge."
    exit 0
fi

BRANCH="sre-dashboard-$(date +%Y%m%d-%H%M%S)"
git checkout -b $BRANCH

git add .

# Determina a mensagem de commit baseada no código de saída do monitor.py
if [ "$MONITOR_EXIT_CODE" -eq 1 ]; then
    git commit -m "alert: performance degradation detected
    
    Automated SRE monitoring detected service degradation.
    Dashboard updated with latest observability metrics.
    
    Services monitored:
    - GitHub Pages (https://pklavc.github.io/)
    - GitHub API (api.github.com/repos/PkLavc/codepulse-monorepo)
    
    Incident response initiated.

    Co-authored-by: pklavc-labs <modderkcaheua@gmail.com>"
else
    git commit -m "stats: update uptime metrics and dashboard data

    Co-authored-by: pklavc-labs <modderkcaheua@gmail.com>"
fi

git push origin $BRANCH --force

# Criar e Mesclar PR com metadados profissionais
PR_URL=$(gh pr create --title "📊 SRE Dashboard: $(date +'%Y-%m-%d %H:%M')" \
                      --body "Automated SRE observability dashboard update and metrics synchronization.

**Changes:**
- Updated uptime metrics in history.json
- Refreshed SRE dashboard visualizations in index.html
- Generated new SLA metrics and performance data
- Updated Shields.io badge with current uptime percentage

**Services Monitored:**
- GitHub Pages (https://pklavc.github.io/)
- GitHub API (api.github.com/repos/PkLavc/codepulse-monorepo)

**Observability Features:**
- SLA calculations (24h, 7d, 30d)
- Performance metrics (DNS, TCP, Transfer times)
- Incident log tracking
- Security headers analysis
- Deep health checks

**Dashboard:** [index.html](./index.html)

🚀 SRE Achievement: Automated observability update completed." \
                      --base main --head $BRANCH)

echo "Merging PR: $PR_URL"
gh pr merge "$PR_URL" --merge --delete-branch --admin