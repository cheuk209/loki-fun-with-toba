# Roadmap & Implementation Guide — Minikube streaming + Grafana / Prometheus / Loki

Goal
- Build a small, Plex-like streaming prototype on Minikube.
- Focus learning: Prometheus (metrics), Loki (logs), Grafana (dashboards).
- Keep resource usage low for a small single-node VM.

Team
- Cheuk — lead on application & Kubernetes deployment tasks.
- Toba — lead on monitoring stack, dashboards, and observability integrations.
- Both — design decisions, testing, and documentation together.

Constraints / target environment
- Single dev VM (recommendation: 2 CPU, 4GB RAM, 20GB disk minimum).
- Minikube with Docker driver running in devcontainer on Ubuntu 24.04.
- Prefer single-instance, minimal replicas, local hostPath storage.

Phases & split of responsibilities

Phase 1 — Plan & prerequisites (shared)
- Tasks:
  - Agree minimal feature set and languages (Cheuk + Toba).
  - Verify host tooling: minikube, kubectl, docker (Cheuk does initial checks; Toba verifies monitoring clients available).
  - Decide Minikube resource target and namespace (shared).

Phase 2 — Start Minikube (Cheuk primary, Toba support)
- Cheuk:
  - Start Minikube and enable ingress/metrics-server.
  - Create project namespace and set up local Docker env for image building.
- Toba:
  - Validate cluster has required API access for monitoring (metrics-server).
  - Provide a small resource-quota YAML for minikube overlay.

Phase 3 — Minimal streaming application (Cheuk primary)
- Cheuk:
  - Scaffold metadata/index service + streamer service (instrument with /metrics).
  - Create lightweight frontend (static SPA or NGINX) and Dockerfiles (alpine/scratch).
  - Add structured JSON logging to stdout.
  - Create k8s manifests (Deployments, Services, minimal resource requests/limits).
- Toba:
  - Review Prometheus instrumentation (help wire client libraries).
  - Test that /metrics endpoints are reachable and scrapeable.

Phase 4 — Observability stack (Toba primary)
- Toba:
  - Deploy minimal Prometheus Deployment with tuned scrape_interval and retention.
  - Deploy Loki single-instance plus Promtail configuration (namespace/container selectors).
  - Deploy Grafana with datasource provisioning for Prometheus + Loki.
  - Create initial dashboards focused on streaming metrics and logs.
- Cheuk:
  - Ensure app labels and metrics are stable; add any missing metrics.
  - Help with promtail log label selection and mount points for hostPath (if used).

Phase 5 — Dashboards, alerts, and UX (Toba lead, Cheuk support)
- Toba:
  - Build focused dashboards: app health, stream throughput, pod resource usage, log errors.
  - Create a minimal alert rule set (error rate, memory use) — webhook or simple notifier.
- Cheuk:
  - Validate dashboard metrics map to app metrics; provide sample data points and test traffic.

Phase 6 — Optimize & scale-down (shared)
- Tasks:
  - Tune Prometheus scrape intervals and retention to reduce memory (Toba).
  - Reduce log retention and adjust Loki compaction settings (Toba).
  - Reduce app resource footprints; optimize Dockerfiles (Cheuk).
  - Run small load tests and iterate (shared).

Implementation checklist with owners
1. Start Minikube
   - Cheuk: minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g
   - Cheuk: kubectl create namespace streaming
2. Build & deploy app images into Minikube
   - Cheuk: eval $(minikube -p minikube docker-env) && docker build -t streaming-api:dev ./src/api
   - Cheuk: kubectl apply -f k8s/streaming-deployment.yaml -n streaming
3. Deploy Prometheus (minimal)
   - Toba: kubectl apply -n streaming -f monitoring/prometheus/prometheus-deployment.yaml
   - Toba: set scrape_interval >=30s and retention ~24h
4. Deploy Loki + Promtail
   - Toba: kubectl apply -n streaming -f monitoring/loki/loki-deployment.yaml
   - Toba: kubectl apply -n streaming -f monitoring/loki/promtail-daemonset.yaml
5. Deploy Grafana and import dashboards
   - Toba: kubectl apply -n streaming -f monitoring/grafana/grafana-deployment.yaml
   - Toba: provision Prometheus + Loki datasources via ConfigMap
6. Validation & handoffs
   - Cheuk: generate sample traffic and verify /metrics and logs visible
   - Toba: verify dashboards and alerts fire on test conditions

Resource tuning suggestions (conservative defaults)
- Prometheus: requests: 200m CPU / 256Mi RAM, limits: 500m / 1Gi
- Grafana: requests: 100m / 128Mi, limits: 300m / 512Mi
- Loki: requests: 200m / 256Mi, limits: 800m / 1Gi
- Promtail: requests: 50m / 64Mi, limits: 200m / 256Mi
- App pods: requests: 100m / 128Mi, limits: 500m / 512Mi

Testing & validation (owners)
- Smoke tests (Cheuk runs; Toba verifies metrics/logs):
  - Confirm app returns 200 and exposes /metrics.
  - Confirm Prometheus scrapes app within one interval.
  - Confirm logs appear in Grafana Explore via Loki.
- Load tests: small scale loops (shared).

Docs & repo deliverables (owners)
- docs/IMPLEMENTATION_GUIDE.md — Cheuk draft, Toba reviews.
- monitoring/ manifests — Toba creates, Cheuk reviews.
- src/ app code — Cheuk creates, Toba instruments.
- scripts/minikube-setup.sh — Cheuk creates.
- k8s/overlays/minikube/resource-quotas.yaml — Toba creates.

Communication & checkpoints
- Weekly short syncs: review progress, swap small tasks to share learning.
- Mid-phase handoff: after app works locally, Toba begins monitoring deployment.
- Final review: both verify dashboards, alerts, and resource limits.

Final notes
- Keep everything minimal and reversible. Prefer ConfigMaps for dashboards and no long-term retention.
- Swap small tasks regularly so both Cheuk and Toba touch app, infra, and observability components.