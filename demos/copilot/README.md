# AWS Copilot
This repository consists code examples for **AWS Copilot CLI**.

**AWS Copilot CLI** is an open source command line interface that makes it easy for developers to build, release, and operate production ready containerized applications on AWS App Runner, Amazon ECS, and AWS Fargate.

## Folder Structure
```
├── cleanup.sh
├── Dockerfile
├── environments
│   └── test
│       └── manifest.yml
├── index.html
├── job1
│   └── manifest.yml
├── links.txt
├── notes.txt
├── pipelines
│   └── manifest.yml
├── README.md
├── web1
│   ├── addons
│   │   └── additional_policy.yml
│   └── manifest.yml
└── web2
    └── manifest.yml
```

## Usage

Loging to AWS or inject credetial using something like `aws-vault`.

* Create cluster using
```bash
copilot init -a app1 -n web1 -e test -t "Load Balanced Web Service" -d ./Dockerfile --deploy
```
* To deploy second web2 service:
```bash
copilot init -a app1 -n web2 -e test -t "Static Site"
```
* You can inspect logs:
```bash
copilot svc logs --follow
```
* To run local container:
```bash
copilot run local --watch &
```
* Check status of the service/deployments:
```bash
copilot svc status
```
* Finally you can scale the deployments using ``kubectl scale deployment <deployment-name> --replicas=10``
* Clean-up:
```bash
./cleanup.sh
```
