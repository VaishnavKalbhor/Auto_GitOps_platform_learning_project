# AutoGitOps Platform

A GitOps-driven Kubernetes platform on AWS using Terraform, EKS, ArgoCD, and Prometheus/Grafana.

## Overview

AutoGitOps Platform is a platform engineering project that provisions an AWS EKS Kubernetes environment using Terraform, deploys workloads using ArgoCD GitOps, and adds Prometheus/Grafana observability. It also validates autoscaling and self-healing behavior under real (or simulated) failure conditions.

This project is deliberately separate from [AutoSecureOps](../autosecureops): AutoSecureOps proves DevSecOps practice around an application; this project proves the ability to build the **platform** such an application runs on.

## Learning Goals

- Provision AWS infrastructure using Terraform
- Use remote Terraform state in S3
- Create an EKS cluster with managed node groups
- Deploy Kubernetes applications using ArgoCD
- Add monitoring with Prometheus and Grafana
- Validate pod self-healing and autoscaling behavior
- Document platform decisions, limitations, and learning progress

## Cost Warning

This project provisions real, billed AWS resources (EKS control plane, NAT Gateway, EC2 worker nodes). See [docs/cost-notes.md](docs/cost-notes.md) before running `terraform apply`. The habit throughout this project is: `terraform apply` → test and screenshot → `terraform destroy`. Do not leave the cluster running.

## Documentation

- [Architecture](docs/architecture.md)
- [Platform Design](docs/platform-design.md)
- [GitOps Workflow](docs/gitops-workflow.md)
- [Observability](docs/observability.md)
- [Autoscaling and Self-Healing](docs/autoscaling-and-self-healing.md)
- [Cost Notes](docs/cost-notes.md)
- [Security Findings](docs/security-findings.md)
- [Learning Log](docs/learning-log.md)
