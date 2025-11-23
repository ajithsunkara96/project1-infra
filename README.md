# Multi-Tier Azure Web Application

## Overview
Enterprise-grade 3-tier web application deployed on Azure using Infrastructure as Code (Terraform).

## Architecture
- **Web Tier:** Nginx reverse proxy (VMSS, Load Balanced)
- **App Tier:** Node.js REST API (VMSS, Internal Load Balancer)  
- **Database Tier:** Azure SQL with Geo-Replication

## Features
✅ Infrastructure as Code (Terraform)
✅ Virtual Machine Scale Sets (auto-scaling capable)
✅ Load Balancers (public + internal)
✅ Multi-zone deployment for high availability
✅ Network Security Groups (defense-in-depth)
✅ Azure SQL with Geo-Replication
✅ Managed Identity authentication (no passwords in code)
✅ NAT Gateway for secure outbound access
✅ User registration system (working end-to-end)

## Technologies
- **Infrastructure:** Azure, Terraform
- **Compute:** VMSS, Ubuntu 20.04 LTS
- **Web Server:** Nginx
- **Application:** Node.js, Express
- **Database:** Azure SQL Database
- **Security:** NSGs, Managed Identity, Azure AD Auth

## Architecture Diagram


## Deployment
```bash
terraform init
terraform plan
terraform apply
```

## Security Features
- Network segmentation (3 isolated subnets)
- NSG rules controlling inter-tier communication
- Azure AD authentication for SQL
- Managed Identity for app-to-database auth
- No passwords in application code

## Cost Estimate
~$373/month for production workload
- Optimizable with smaller SKUs for dev/test
