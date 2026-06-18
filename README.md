# Sterling Checkout — AWS RDS Infrastructure Layer

This repository contains the production-grade Infrastructure as Code (IaC) definitions and architectural specifications for the data layer of the **Sterling Checkout** SaaS platform (Sterling Commerce).

## Repository Structure
* `main.tf` — Core Terraform configurations (VPC, fine-grained Security Groups, KMS Key, Parameter Groups, and Multi-AZ RDS instance).
* `variables.tf` — Environment input variables with sensitive data masking.
* `database_requirements_summary.md` — Plain-text specification of the transactional data layer requirements.
* `production_readiness_criteria.md` — Evaluation framework and criteria used for production acceptance.
* `verification_results.md` — Real execution logs, connectivity outputs, and verification traces confirming deployment status.

## Core Security & Architecture High-points
1. **Zero Public Exposure:** The database has `publicly_accessible = false` and resides in isolated private subnets.
2. **Microservice-Level Least Privilege:** No wide CIDR ingress rules. Ingress to port 5432 is explicitly chained to specific application security groups.
3. **Enforced At-Rest & In-Transit Encryption:** Handled via dedicated Customer Managed Keys (KMS AES-256) and strict database parameter groups (`rds.force_ssl = 1`).
