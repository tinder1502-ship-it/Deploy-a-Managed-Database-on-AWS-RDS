# Production Readiness Criteria Framework

This document outlines the acceptance gates used to evaluate and verify the structural viability of the Sterling Checkout AWS RDS cluster.

| Gate ID | Target Domain | Verification Methodology & Mandatory Metric |
| :--- | :--- | :--- |
| **NET-01** | Network Contained | Execute AWS CLI metadata verification. Confirm `PubliclyAccessible` state evaluates to exactly `false`. Check route tables to verify zero external target gateways are associated with the DB subnets. |
| **SEC-01** | At-Rest Encryption | Assert that `StorageEncrypted` equals `true`. Cross-reference structural ARN maps to confirm integration with the verified Customer Managed Key (KMS AES-256 cipher). |
| **SEC-02** | In-Transit Compliance | Verify active DB Parameter Groups have `rds.force_ssl = 1` set. Connection attempts using unencrypted plaintext parameters must be aborted instantly by the database engine. |
| **SEC-03** | Ingress Security | Audit Security Group mappings to port 5432. Ingress rules must contain zero raw open CIDR values (`0.0.0.0/0` or `10.0.0.0/16` open rules are failures). Ingress must explicitly chain to application/bastion Security Group IDs. |
| **PERF-01**| Latency Check | Run synthetic benchmark suites matching peak holiday traffic spikes. Confirm write transactions maintain steady execution windows below the 15ms barrier. |
| **OPS-01** | High Availability | Execute a synthetic failure on the primary node. Automated Multi-AZ tracking must promote the secondary standby replica in `< 60 seconds` with complete zero data loss (`RPO = 0`). |
