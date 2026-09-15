# AWS Resource Usage Tracker (Shell Script)

A Bash script that generates a daily report of AWS resource usage — EC2 instances, S3 buckets, Lambda functions, and IAM users — using the AWS CLI, `jq`, and a scheduled `cron` job. Built as a hands-on DevOps project to practice combining shell scripting with the AWS CLI for a real-world cost-tracking use case.

## Why this project

Cloud providers bill on a pay-as-you-go basis, which is one of the main reasons organizations move to the cloud in the first place. But that benefit only holds if resource usage is actually tracked — developers commonly spin up EC2 instances, EBS volumes, or other resources and then forget about them, and AWS has no way of knowing a running resource is unintentional. It simply charges for what's provisioned.

Tracking resource usage across an account — and reporting it, e.g. to a manager or dashboard — is a common, real responsibility for DevOps engineers and a practical way to support cost control. This script is a simple, from-scratch implementation of that idea.

## What it does

The script runs four read-only AWS CLI commands and prints a labeled report for each:

| Resource | Command |
|---|---|
| S3 buckets | `aws s3 ls` |
| EC2 instances | `aws ec2 describe-instances \| jq '.Reservations[].Instances[].InstanceId'` |
| Lambda functions | `aws lambda list-functions` |
| IAM users | `aws iam list-users \| jq '.Users[].UserName'` |

Additional features:
- **Debug mode (`set -x`)** — prints each command before it runs, alongside its output, so the report clearly shows what was executed and what it returned.
- **`jq` filtering** — the raw `describe-instances` and `list-users` responses are verbose JSON; `jq` extracts just the fields that matter (instance IDs, usernames) instead of dumping the full response.
- **Output redirection** — the full report can be redirected to a file for easy sharing instead of only appearing in the terminal.

None of these are billed API calls — `describe-instances`, `list-functions`, `list-users`, and `s3 ls` are all free read/list operations.

## Prerequisites

- AWS CLI installed and configured (`aws configure`) with valid credentials
- `jq` installed
- Bash (the script explicitly uses `#!/bin/bash` rather than `#!/bin/sh`, since `sh` may symlink to `dash` on some systems and cause syntax issues)

## Usage

```bash
chmod +x aws-resource-tracker.sh
./aws-resource-tracker.sh
```

To save the report to a file instead of just printing it:

```bash
./aws-resource-tracker.sh > resource-tracker-report.txt
```

## Automating it with cron

The script is scheduled to run automatically every day using a personal crontab entry:

```
0 18 * * * /path/to/aws-resource-tracker.sh >> /path/to/cron.log 2>&1
```

- `0 18 * * *` — runs at 18:00 (6 PM) every day, regardless of date or weekday
- `>> cron.log` — appends each day's output to a running log rather than overwriting it
- `2>&1` — redirects stderr into the same stream as stdout, so errors are captured in the log too, since cron jobs run unattended with no terminal to display errors on

Setup:
```bash
crontab -e
# add the line above, using the absolute path to the script
crontab -l   # confirm it saved
```

## A debugging note: the AWS CLI pager

While testing the script in an environment stripped of normal shell variables (to simulate exactly how cron would run it), one command — `aws lambda list-functions` — hung with:

```
WARNING: terminal is not fully functional
Press RETURN to continue
```

This is the AWS CLI's built-in pager (similar to `less`), which it invokes automatically for commands that print directly to a terminal. Commands piped into another program (like `describe-instances | jq`) skip the pager since their output isn't going to a screen — but `list-functions` prints straight to stdout, so the CLI tried to page it. With no real terminal attached (as would be the case under cron), the pager can hang indefinitely waiting for input that will never come.

Fix — disable the pager globally at the top of the script:

```bash
export AWS_PAGER=""
```

This ensures the script behaves identically whether run interactively or from an unattended cron job.

## Possible extensions

- Convert to a modular script using functions instead of a linear structure
- Send the generated report via email or to Slack instead of a local file
- Rebuild using AWS Lambda + EventBridge Scheduler for a serverless, no-idle-compute version of the same idea
- Add cost estimates (e.g. via Cost Explorer API) alongside the raw resource counts

## Author

Neha — built as part of a self-directed DevOps learning path (AWS Cloud Practitioner prep, shell scripting, Docker, and Kubernetes).
