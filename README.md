# Monitor-pastebin-leaks
Script to monitor pastebin.com's public pastes for sensitive data leakage.

It "greps" raw data against regular expressions,

**if matches**
1. downloads file to */opt/pastebin/* directory
2. gives you alert
3. saves message in log

#### NOTE: Script is tested only for root user.

### Usage
_How to run?_
```bash
bash MONITOR_pastebin.sh
```
_How to add to cron?_
```bash
crontab -l | { cat; echo "*/5 * * * * bash MONITOR_pastebin.sh"; } | crontab -
```

### Screenshots
> When nothing changed after the last run

![When nothing changed after the last run](https://i.imgur.com/PskxChx.png)

> When something changed after the last run

![When something changed after the last run](https://i.imgur.com/A07gM5T.png)

> When script finds something

![When script finds something](https://i.imgur.com/8jr6IHL.png)

> Data downloaded in /opt/pastebin

![Data downloaded in /opt/pastebin](https://i.imgur.com/pfhusMP.png)
