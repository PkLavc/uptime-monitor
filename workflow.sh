#!/bin/bash
set -e # Para o script se qualquer comando falhar

git config user.name "PkLavc"
git config user.email "patrickajm@gmail.com"

BRANCH="status-$(date +%s)"
git checkout -b $BRANCH

git add uptime_log.txt
git commit -m "chore: update uptime status"
git push origin $BRANCH --force

echo "Criando PR..."
PR_URL=$(gh pr create --title "Uptime Check $(date +'%H:%M')" --body "Automated check" --base main --head $BRANCH)

echo "Dando Merge no PR: $PR_URL"
gh pr merge "$PR_URL" --merge --admin
