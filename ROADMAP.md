# Roadmap & Implementation Guide — Minikube streaming + Grafana / Prometheus / Loki

Goal
- Build a small, Plex-like streaming prototype on Minikube.
- Focus learning: Prometheus (metrics), Loki (logs), Grafana (dashboards).
- Keep resource usage low for a small single-node VM.

Constraints / target environment
- Single dev VM (recommendation: 2 CPU, 4GB RAM, 20GB disk minimum).
- Minikube with Docker driver running in devcontainer on Ubuntu 24.04.
- Prefer single-instance, minimal replicas, local hostPath storage.

Phases (milestones)
1. Plan & environment
2. Minikube lightweight cluster
3. Minimal streaming app (producer + simple frontend)
4. Observability: Prometheus, Loki, Grafana
5. Dashboards, basic alerts, and optimizations
6. Tests, CI notes, cleanup

Phase 1 — Plan & prerequisites (1–2 days)
- Define minimal feature set: library index, stream endpoint (HTTP), simple UI.
- Decide languages for components (e.g., Go for backend, lightweight node/React for UI).
- Install tools on host: minikube, kubectl, docker (available in devcontainer).
- Recommended Minikube target: 2 CPU, 4GB RAM. If less hardware, reduce services.

Phase 2 — Start Minikube (quick)
- Start command (adjust resources to your host):
  - minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g
- Enable ingress if needed:
  - minikube addons enable ingress
- Enable metrics-server (optional for HPA):
  - minikube addons enable metrics-server
- Use a single namespace for project:
  - kubectl create namespace streaming

Phase 3 — Minimal streaming application (2–4 days)
- Make components:
  - metadata/index service (small REST API, exposes /metrics)
  - streamer service (serves files via HTTP range requests)
  - frontend (static SPA or NGINX proxy)
- Container images: build small images (alpine base, scratch where possible).
- Expose metrics: instrument services with Prometheus client (e.g., prometheus-client for Python, promhttp for Go).
- Logging: structured JSON to stdout (key for Loki ingestion).
- Resource requests/limits (example conservative):
  - requests: cpu: 100m, memory: 128Mi
  - limits: cpu: 500m, memory: 512Mi
- Local image workflow: build and load into Minikube:
  - eval $(minikube -p minikube docker-env)
  - docker build -t streaming-api:dev ./src/api
  - kubectl apply -f k8s/...

Phase 4 — Observability stack (3–5 days)
Design goals:
- Single-instance, low-memory Prometheus & Loki.
- Grafana single pod with small PVC or no PVC (provision dashboards via ConfigMap).

Prometheus (lightweight)
- Use a single Deployment (not the full kube-prometheus-stack) to save resources.
- Scrape interval: 30s or 60s to reduce load.
- Retention: short (e.g., 24h) to save disk.
- Example tuned flags:
  - --storage.tsdb.retention.time=24h
  - --storage.tsdb.min-block-duration=2h
- Prometheus config: scrape your app endpoints and kubelet/metrics only if needed.

Loki (single-instance)
- Run single-statefulset or deployment with hostPath storage for chunks/index.
- Tune limits:
  - chunk_target_size: 1048576 (1MB)
  - ingester.max_chunk_age: 1h
  - retention via compactor disabled for single-node (manual cleanup)
- Use promtail to ship logs; keep promtail small (tail only app containers).

Grafana
- Single Deployment with low resource requests.
- Provision datasource and dashboards via ConfigMap (auto provisioning).
- Optionally use ephemeral dashboards (no PVC) if you can recreate them from code.

Phase 4 — Sample configs & key knobs (snippets)
- Prometheus: scrape less often, minimal features.
- Loki: file store, compact disabled, low memory limits.
- Promtail: target specific namespace/containers.

(Include these small example snippets in your manifests — keep configs minimal: single jobs, short retention.)

Phase 5 — Dashboards, alerts, and UX (1–3 days)
- Create focused dashboards:
  - App health (uptime, request rate, error rate)
  - Stream throughput (bytes/sec), active streams
  - Node/Pod resource usage (cpu, memory)
  - Loki log rate & errors
- Alerts (optional):
  - High error rate for streaming service
  - High pod memory usage
  - Set alertmanager later if required; for now send alerts via simple webhook.

Phase 6 — Optimize & scale-down (ongoing)
- Lower Prometheus scrape frequency if memory/CPU is high.
- Reduce retention windows for metrics and logs.
- Use log label selectors in Loki/promtail to avoid tailing noisy containers.
- Avoid running extra agents (e.g., don’t use full kube-state-metrics if not needed).

Implementation checklist (concrete steps)
1. Start Minikube:
   - minikube start --driver=docker --cpus=2 --memory=4096 --disk-size=20g
   - kubectl create namespace streaming
2. Build & deploy app images into Minikube’s Docker:
   - eval $(minikube -p minikube docker-env)
   - docker build -t streaming-api:dev ./src/api
   - kubectl apply -f k8s/streaming-deployment.yaml -n streaming
3. Deploy Prometheus (minimal):
   - kubectl apply -n streaming -f monitoring/prometheus/prometheus-deployment.yaml
   - Replace scrape_interval with 30s+ and set retention to 24h
4. Deploy Loki + Promtail:
   - kubectl apply -n streaming -f monitoring/loki/loki-deployment.yaml
   - kubectl apply -n streaming -f monitoring/loki/promtail-daemonset.yaml
5. Deploy Grafana and import dashboards:
   - kubectl apply -n streaming -f monitoring/grafana/grafana-deployment.yaml
   - Use provisioning to auto-add Prometheus and Loki datasources
6. Validate:
   - kubectl port-forward svc/grafana 3000:3000 -n streaming
   - curl <app>/metrics
   - Check logs in Grafana Explore (Loki datasource)

Resource tuning suggestions (conservative defaults)
- Prometheus: requests: 200m CPU / 256Mi RAM, limits: 500m / 1Gi
- Grafana: requests: 100m / 128Mi, limits: 300m / 512Mi
- Loki: requests: 200m / 256Mi, limits: 800m / 1Gi
- Promtail: requests: 50m / 64Mi, limits: 200m / 256Mi

Testing & validation
- Smoke tests:
  - Hit streaming endpoints and assert 200 + metrics appear in Prometheus within 1 scrape interval.
  - Check logs in Grafana Explore via Loki for recent requests.
- Load test small (hey or curl loops) to measure resource saturation; keep conservative.

CI / Dev workflow notes
- Build images locally during dev and load into Minikube (minikube image load).
- Keep manifests small and declarative; use kustomize overlays for minikube to set resource quotas.
- Use GitHub Actions for CI that runs unit tests only (don’t run cluster in CI unless necessary).

Useful commands (quick)
- minikube dashboard
- kubectl -n streaming get pods,svc,deploy
- kubectl -n streaming port-forward svc/grafana 3000:3000
- kubectl logs -n streaming deploy/streaming-api

Troubleshooting tips (short)
- If node memory is exhausted: scale down or stop nonessential services.
- If Prometheus OOMs: increase scrape_interval and reduce retained time.
- If Loki storage grows fast: reduce retention and increase compaction intervals.

Deliverables to create in repo (suggested files)
- docs/IMPLEMENTATION_GUIDE.md (this file)
- k8s/ overlays/minikube/resource-quotas.yaml (conservative limits)
- monitoring/ (prometheus, grafana, loki subfolders with minimal manifests)
- src/ (small example API + frontend)
- scripts/minikube-setup.sh (one-liner start + env setup)
- scripts/build-images.sh (build and load into minikube)

Final notes
- Prioritise small data retention windows and longer scrape intervals to save resources.
- Start simple: single-instance Prometheus & Loki; add complexity only as needed.
- Keep logs structured and metrics minimal — that yields the fastest insight with least overhead.

If you want, I can scaffold the following next:
- A minimal k8s manifests pack for Prometheus, Loki, Promtail, Grafana tuned for Minikube
- A tiny streaming API (Go) with /metrics and JSON logs
- Grafana provisioning files and a starter dashboard

Choose one and I will scaffold the files into the repo.