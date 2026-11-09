# Deploying on the Ubuntu home-lab server

Nothing in this directory has been run. Treat it as a starting point and verify each
step. Every image tag needs pinning to a digest before the system holds a real job —
"the version that produced this result" is part of the record under ISO 8.3.

## Host preparation

1. **Storage.** Put the Docker data root and the Postgres volume on an encrypted
   volume (LUKS). The system holds client-confidential assessment records.
2. **Firewall.** `ufw default deny incoming`, allow SSH from the LAN and 443 from the
   LAN and the VPN subnet only. Do not forward a port from the router.
3. **Remote access.** WireGuard or Tailscale. The system is never published to the
   internet.
4. **Updates.** `unattended-upgrades` for security patches on the host. Container
   images are upgraded deliberately, not automatically.
5. **SSH** by key only, root login disabled, a non-root user in the `docker` group.
6. **Time.** Confirm NTP is synchronised. Timestamps are evidence.
7. **Physical security.** A locked room or cabinet, and that fact recorded — an
   assessor will ask where the records live.

## First run

```bash
cp infra/.env.example infra/.env        # fill in the secrets, chmod 600
docker compose -f infra/docker-compose.yml build
docker compose -f infra/docker-compose.yml up -d postgres redis
docker compose -f infra/docker-compose.yml run --rm app php artisan key:generate
docker compose -f infra/docker-compose.yml run --rm app php artisan migrate
docker compose -f infra/docker-compose.yml run --rm app php artisan db:seed
docker compose -f infra/docker-compose.yml up -d
```

Then install the audit triggers and revoke the grants (see
`infra/initdb/10-audit-immutability.sql`) and **prove the revocation works** before
going further.

## Backup

The requirement is three copies: the server, a second machine or NAS on the LAN, and an
encrypted offline or off-site copy. The offline copy is what survives ransomware on the
LAN.

- Nightly logical dump plus continuous WAL archiving, so recovery is not limited to
  last night.
- Encrypt at rest with a key held outside the server.
- **Test the restore quarterly into a scratch container and record the test.** An
  untested backup is a belief, not a control, and this is the first thing an assessor
  asks to see evidence of.
- Proposed RPO 24 hours, RTO one working day — confirm these are acceptable.

**The gap to close separately:** evidence files live in the job folder, outside this
stack, and none of the above covers them. The job folder needs its own backup under the
same policy, or the lab is protecting the index and not the evidence.

## Upgrades

Snapshot the database, pull the pinned digest, migrate, smoke-test the gate rules, and
roll back by restoring the snapshot if the smoke test fails. Record the version change
and the reason — this is a controlled change, not a routine one.

## Sizing

Register-only means the database holds text and numbers for a few dozen jobs a year.
2 vCPU, 8 GB RAM and 50 GB on the data volume is generous. Growth comes from the audit
log, not from the jobs.
