# Local Runtime Architecture: Docker, Kubernetes, and Cloud Run Path

This note evaluates running local service instances on a Mac mini and preserving a future migration path to Google Cloud.

## Current Machine

Observed locally:

- Machine: Mac mini, Apple M4, 10 cores.
- Memory: 16 GB.
- Disk: 228 GiB volume, about 161 GiB available.
- Architecture: arm64.

This is enough for a useful local container runtime, but not enough to treat the Mac mini like a large multi-node cluster. Keep the base runtime lean and set hard CPU/memory/disk limits.

## Short Recommendation

Use Docker Compose first, with a Cloud Run-compatible container contract:

- Every service is an OCI container.
- Every HTTP service listens on `$PORT`, default `8080`.
- Logs go to stdout/stderr.
- Configuration comes from environment variables and mounted secrets.
- Persistent state is explicit and externalized.
- No dependency on host paths unless intentionally declared.
- Local traffic goes through `localhost` via a small reverse proxy.

Add Kubernetes later when you need Kubernetes-specific features:

- namespaces and RBAC for multiple users/agents
- ingress controllers
- Helm charts
- service mesh
- multi-service scheduling policies
- closer migration to GKE rather than Cloud Run

For this project, Docker CLI with Colima is the better default. Kubernetes is more powerful, but it adds operational surface area that is not needed for a Cloud Run-like local setup.

Current decision: this Mac mini is treated as one trusted agent instance. Local agents share the same machine-level access model instead of having separate local permission boundaries. Fine-grained access control is expected to happen in external services, especially Google Cloud, when separate accounts or deployed services are created there.

## Why Docker First

Docker Compose is designed for defining and running multi-container apps from one YAML file. It gives the project enough structure for local services, networks, volumes, logs, lifecycle commands, and reproducible startup.

This maps well to Cloud Run because Cloud Run runs containers. Google documents Cloud Run as a fully managed platform for request/event-invoked containers, and its local testing docs explicitly support running Cloud Run container images locally with Docker.

The key migration path is:

```text
Dockerfile -> local docker compose -> Artifact Registry -> Cloud Run service
```

Not every Compose feature maps to Cloud Run. Treat Compose as local wiring, not as the production deployment spec.

## When Kubernetes Becomes Worth It

Use Kubernetes locally if the future target is GKE, not Cloud Run.

Kubernetes is appropriate when:

- services need Kubernetes-native discovery and policies
- agents need scoped access through Kubernetes RBAC
- you need namespaces per project, user, or agent
- you want to test Helm charts
- you expect the production target to be GKE Autopilot or GKE Standard

For local Kubernetes, prefer:

```text
kind
k3d
Colima Kubernetes
Docker Desktop Kubernetes
```

Avoid always-on Kubernetes on this 16 GB machine unless it is actively used. A small cluster plus browsers and AI tools can consume memory quickly.

## Cloud Run-like Local Model

Recommended local routing:

```text
localhost:8080  -> gateway/reverse-proxy
localhost:8081  -> service-a
localhost:8082  -> service-b
localhost:8083  -> worker control endpoint
```

Better long-term model:

```text
localhost:8080/api/service-a -> service-a:8080
localhost:8080/api/service-b -> service-b:8080
localhost:8080/internal/*     -> internal-only services
```

Use Caddy, Traefik, or nginx as a lightweight gateway. The gateway becomes the stable local interface while service containers can be rebuilt and restarted behind it.

Each service should include:

```text
/healthz
/readyz
/version
```

Every service should support:

```text
PORT=8080
LOG_LEVEL=info
SERVICE_NAME=...
ENVIRONMENT=local
```

## Local Agent Access Model

Current decision: do not implement separate local roles or permission boundaries between agents on this Mac mini. The machine is treated as one trusted local agent runtime. Abstract agents may have different tasks, but they share the same effective access to the project, local runtime, Keychain-backed secrets, and machine-level tools available to the chosen macOS account.

This keeps the local setup simpler and matches the intended use: one dedicated Mac mini acting like a single virtual instance for agent workloads.

What this means:

- no per-agent local RBAC
- no separate local runtime-controller permission model for now
- no local allowlist enforcement for each abstract agent
- containers are used for reproducibility and runtime organization, not as the main local security boundary
- external services and Google Cloud remain responsible for fine-grained access control when separate deployed services or accounts are needed

Practical consequences:

- Secrets in macOS Keychain are considered available to the trusted local agent account.
- Agents may manage Colima/Docker and local project files within the same overall trust boundary.
- Monitoring and logs still matter, because they explain what happened on the machine.
- Destructive operations should still be handled carefully, but not through a per-agent permission framework.

## Do Agents Need Containers?

For this project, yes, containers are worth it for most agent-run work.

They add some overhead, but they also provide:

- reproducible environments
- isolated dependencies
- easier cleanup
- explicit CPU/memory limits
- a clean path toward Cloud Run or GKE

Use containers for:

- project builds
- tests
- experiments
- generated apps
- local services
- agent-created prototypes

Avoid containers for:

- macOS preference changes
- Homebrew/bootstrap installation
- tools that must control the actual desktop UI
- tasks that need direct access to Apple-specific frameworks or user sessions

The common industry pattern is layered:

```text
host bootstrap -> containerized dev/runtime -> controlled deployment target
```

For coding environments, dev containers are also a known pattern: they define a full-featured development environment inside a container with project-specific tools and settings.

## Container Runtime Defaults

Even without local per-agent permission boundaries, services should still have sane runtime defaults. These settings reduce accidental damage, make resource use predictable, and keep services closer to Cloud Run/GKE expectations:

```yaml
security_opt:
  - no-new-privileges:true
read_only: true
cap_drop:
  - ALL
mem_limit: 512m
cpus: "1.0"
pids_limit: 256
restart: unless-stopped
```

Only relax these defaults when a service actually needs it.

Avoid by default:

```text
privileged: true
host network mode
mounting / or $HOME
mounting Docker socket
running as root
unbounded memory
```

Use internal Docker networks so services talk to each other by service name, not by random host ports.

## Resource Budget

For this Mac mini:

### Colima Docker-first resource budget

- Colima memory: 6 GB.
- Colima CPUs: 4.
- Disk image limit: 60-100 GB.
- Good for: 3-8 small services, databases for development, workers, local gateway.

### Kubernetes resource budget

- Colima memory: 8-10 GB.
- Colima CPUs: 4-6.
- Disk image limit: 80-120 GB.
- Good for: one small local cluster, test namespaces, Helm/GKE-style workflows.
- Risk: memory pressure when browsers, IDEs, Docker, Kubernetes, and AI tools run together.

### Practical limits

Run local databases carefully. Postgres, Redis, and one queue are fine. Multiple heavy databases plus Kubernetes will be uncomfortable on 16 GB.

Use explicit volume cleanup:

```bash
docker system df
docker builder prune
docker volume ls
```

Do not put automatic destructive cleanup in bootstrap scripts.

## Future Google Cloud Migration

### If target is Cloud Run

Keep apps simple:

- one container per service
- stateless HTTP services
- background jobs become Cloud Run jobs
- events come from Pub/Sub, Eventarc, or Cloud Scheduler
- secrets move to Secret Manager
- images move to Artifact Registry
- logs go to Cloud Logging
- metrics and alerts go to Cloud Monitoring

Deployment shape:

```bash
gcloud run deploy service-a \
  --image REGION-docker.pkg.dev/PROJECT/REPO/service-a:TAG \
  --region REGION \
  --allow-unauthenticated
```

Use private services and IAM-based invocation for internal-only endpoints.

### If target is GKE

Use Kubernetes manifests or Helm from the start:

```text
Deployment
Service
Ingress/Gateway
ConfigMap
Secret
HorizontalPodAutoscaler
NetworkPolicy
```

This is more flexible, but it is not "serverless-like" by default.

## Proposed Project Structure

Add later:

```text
runtime/
  compose.yaml
  gateway/
    Caddyfile
  services/
    example-node/
      Dockerfile
      package.json
      src/
scripts/
  runtime/
    up.sh
    down.sh
    logs.sh
    restart.sh
    status.sh
```

Optional Kubernetes later:

```text
k8s/
  base/
  overlays/
    local/
    gke/
```

## Decision

For this bootstrap project:

1. Keep Docker CLI with Colima as the default runtime.
2. Add Docker Compose-based local services when the first real service exists.
3. Design services to satisfy the Cloud Run container contract.
4. Treat the Mac mini as one trusted local agent instance.
5. Use containers for reproducibility and runtime organization, not for local per-agent access separation.
6. Add Kubernetes only when the target changes from Cloud Run to GKE or when cloud-style orchestration becomes essential.

## References

- Cloud Run documentation: https://cloud.google.com/run/docs
- Cloud Run local testing: https://cloud.google.com/run/docs/testing/local
- GKE overview: https://cloud.google.com/kubernetes-engine/docs/concepts/kubernetes-engine-overview
- Docker Compose documentation: https://docs.docker.com/compose/
