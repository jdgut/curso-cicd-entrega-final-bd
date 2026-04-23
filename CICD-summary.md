# CI/CD Pipeline Design Summary — Database Repository

This document summarizes the design decisions, validated assumptions, and final outcomes agreed upon during the setup of the GitHub Actions CI/CD pipeline for the **PostgreSQL database repository** that is part of a three-repository website deployment (frontend, backend, database).

***

## 1. Repository & Branching Model

The repository follows a **two-branch model**, identical to the backend repository:

*   **development**
    *   Active development branch
    *   Used for continuous integration and generation of pre‑production database images

*   **main**
    *   Stable branch
    *   Represents production‑ready database definitions and initialization logic

Both branches already exist in the repository.

***

## 2. Repository Purpose

This repository is responsible for:

*   PostgreSQL **schema definitions**
*   **Initialization scripts** executed at container startup
*   Validation that a fresh database initializes correctly from scratch

The output artifact is a **Docker image** containing:

*   A PostgreSQL base image
*   Database initialization logic (schema + seed/initial data if applicable)

This image is consumed by the backend and deployment environments.

***

## 3. High‑Level Pipeline Goals

The CI/CD pipeline is designed to:

*   Validate database structure and initialization correctness
*   Enforce SQL and Dockerfile quality standards
*   Ensure database initialization is reproducible and deterministic
*   Publish branch‑specific Docker images
*   Avoid generating Docker artifacts from unmerged Pull Requests
*   Centralize pass/fail decisions using SonarCloud quality gates

***

## 4. Final Agreed Behavior

### ✅ Development Branch (`development`)

Triggered on: `push`

*   Run full CI:
    *   Dockerfile linting (Hadolint)
    *   SQL linting (sqlfluff, PostgreSQL dialect)
    *   Docker image build
    *   PostgreSQL container startup
    *   Verification that initialization scripts run successfully
    *   SonarCloud quality gate evaluation
*   Build Docker image
*   Push Docker image to Docker Hub with tag: `dev`

***

### ✅ Pull Requests (`development → main`)

Triggered on: `pull_request`

*   Run full CI only:
    *   Linting
    *   Build
    *   Container startup
    *   Initialization verification
    *   SonarCloud quality gate
*   ❌ **No Docker image push**
*   ❌ **No Docker tags published**

**Rationale:**  
Pull Requests represent temporary, unapproved states. Publishing database images from PRs would create non‑authoritative artifacts that do not correspond to a permanent branch or commit.

***

### ✅ Main Branch (`main`)

Triggered on: `push`

*   Run full CI (same checks as `development`)
*   Build Docker image
*   Push Docker image to Docker Hub with tag: `latest`

***

## 5. Docker Strategy

### Image Purpose

The Docker image represents a **self‑initializing PostgreSQL database**, used to validate schema correctness and provide deployment‑ready database state.

### Image Naming

Docker images follow the same convention as other repositories:

    <DOCKERHUB_USERNAME>/<github-repository-name>:<tag>

Examples:

*   `johndoe/db-repo:dev`
*   `johndoe/db-repo:latest`

### Repository Creation

*   Docker Hub repository does **not** need to exist beforehand
*   It is automatically created on first successful push
*   Repository is **public**

***

## 6. CI Validation Rules (Quality Bar)

A CI run is considered **successful only if all mandatory checks pass**:

### ✅ Mandatory (Must Pass)

*   Dockerfile linting (Hadolint)
*   SQL linting (sqlfluff)
*   Docker image build
*   PostgreSQL container startup
*   Verification that initialization scripts ran correctly

### ⚠️ Informational Only

*   Security scanning (Trivy)
    *   Vulnerabilities are reported
    *   **Failures do NOT break the pipeline**

This balance ensures strong validation without blocking delivery on non‑actionable security findings.

***

## 7. SonarCloud Strategy

*   The repository **already exists in SonarCloud**
*   SonarCloud does **not analyze source files directly**
*   SonarCloud is used as a **centralized quality gate**, aggregating results from:
    *   Linting tools
    *   CI execution outcomes
*   Existing Sonar configuration is present but **must be adapted** for this repository to:
    *   Reflect database‑specific checks
    *   Exclude direct code analysis
    *   Correctly enforce the quality gate

SonarCloud acts as the **final pass/fail signal** for the pipeline.

***

## 8. Dockerfile & Build Context

*   Dockerfile exists at the repository root
*   Build context is the repository root (`.`)
*   No build‑time secrets or environment variables are required
*   Runtime configuration (database credentials, network settings) is handled exclusively by CI and deployment tooling

This guarantees deterministic, portable Docker builds.

***

## 9. Secrets & Variables

The pipeline requires the same global credentials as other repositories:

### Variables

*   `DOCKERHUB_USERNAME`
*   `SONAR_HOST_URL`

### Secrets

*   `DOCKERHUB_TOKEN`
*   `SONAR_TOKEN`

No database credentials are stored in GitHub Secrets for build‑time use beyond ephemeral CI validation.

***

## 10. GitHub Environments

*   GitHub Environments are **not used**
*   No manual approvals
*   No environment‑scoped secrets
*   Pipeline is fully automated and non‑blocking

***

## 11. Key Design Principles Followed

*   ✅ **Artifact Traceability**
    *   Every published image maps to a permanent branch and commit

*   ✅ **No Artifact Pollution**
    *   PRs never produce publishable Docker images

*   ✅ **Deterministic Database Initialization**
    *   Every CI run validates clean‑slate DB creation

*   ✅ **Pipeline Symmetry**
    *   Database CI behavior mirrors backend CI for consistency

*   ✅ **Clear Quality Gate Ownership**
    *   SonarCloud serves as the final authority, not as a linter

***

## 12. Result

The resulting CI/CD pipeline:

*   Reliably validates PostgreSQL initialization logic
*   Ensures schema correctness before any deployment
*   Produces meaningful Docker artifacts (`dev`, `latest`)
*   Integrates cleanly into a multi‑repo deployment architecture
*   Is easy to extend later with CD or migrations if needed

***

## 13. Possible Future Enhancements (Out of Scope)

*   Migration tooling integration (Flyway, Liquibase, etc.)
*   Schema drift detection
*   Versioned database image tags
*   Automated deployment hooks
*   Environment‑specific database validation
