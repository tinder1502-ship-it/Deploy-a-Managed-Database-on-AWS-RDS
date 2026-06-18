# Database Requirements Summary — Sterling Checkout

## 1. Core Architectural Mandate
* **Engine Family:** Managed relational database infrastructure utilizing AWS RDS PostgreSQL (v15.4) or Amazon Aurora PostgreSQL to guarantee robust ACID compliance for financial transaction workflows.
* **Environment Tier:** Production-grade customer-facing ecosystem serving active merchants across North America (NA) and Europe (EU).
* **Availability Model:** Multi-AZ (Availability Zone) deployment providing synchronous block-level replication to eliminate single points of failure.

## 2. Transactional Workload Profile
* **Throughput Dynamics:** High Transactions Per Second (TPS) profile driven by continuous checkout mutations, transaction ledger writing, and parallel state updates.
* **Read/Write Distribution:** Balanced but split. High write volume from customer checkouts; sudden burst lookup requests from merchant dashboards and operational reporting microservices.
* **Latency Limits:** Strict SLA bounding end-to-end database engine execution responses to under 15 milliseconds for checkout writes.

## 3. Perimeter & Access Strategy
* **Network Isolation:** Complete network air-gapping. No internet-facing gateways routed to the data tier. Hosted entirely inside locked private subnets (`10.0.1.0/24` and `10.0.2.0/24`).
* **Security Architecture:** Dual-layer defense-in-depth:
  * Network rules restrict access to known security groups belonging to backend applications.
  * Admin tasks isolated via multi-factor authentication (MFA) Bastion proxy using Just-In-Time short-lived security tokens.
