# GPU VFIO Passthrough — Fleet Remediation Plan

This document is the operational and engineering plan for resolving VFIO/GPU passthrough failures observed across the Thinkmay worker fleet (June 2026 `dmesg` triage). It complements the root-cause analysis and patches documented in [gpu_passthrough_analysis.md](./gpu_passthrough_analysis.md).

**Related code:**

| Area | Path |
|------|------|
| PCIe attach, power stabilization, cooldown | `worker/proxy/qemu/pcie.go` |
| GPU quarantine, refresh, claim | `worker/proxy/qemu/manager.go` |
| Persistent taint store | `worker/proxy/qemu/gpu_taint_store.go` |
| Pre-attach health + guest feedback | `worker/proxy/qemu/gpu_feedback.go` |
| PCI bus rescan | `worker/proxy/qemu/pci_rescan_linux.go` |
| Live dmesg watcher | `worker/daemon/job.go` (`watchPCIFailure`, `filterErrorDmesg`) |
| Manual GPU ops CLI | `worker/daemon/cmd/mgmt/` |

---

## 1. Executive summary

Fleet `dmesg` greps revealed three distinct failure classes:

| Class | Symptom | Likely cause | Action |
|-------|---------|--------------|--------|
| **A — Launch blockers** | `stuck in D3`, FLR timeout, BAR-restore storms | Device stuck after VFIO reset / bad teardown | Quarantine + recovery workflow |
| **B — Link / hardware** | Chronic AER `RxErr` / `BadTLP` | Riser, slot, or cable | Physical inspection |
| **C — Benign noise** | `D0→D3hot, device inaccessible` on `.0`/`.1` pairs | Normal VFIO teardown race | Do **not** auto-quarantine |

Software already implements strong mitigations (`pcie-root-port` topology, `stabilizePassthroughPower`, `gpu_taint.yaml`, pre-attach config-space checks). The main gaps are:

1. **Over-aggressive dmesg quarantine** — `filterErrorDmesg` treats benign teardown warnings the same as fatal wake failures.
2. **No automated recovery** after severe failures — `UnbindGPU` quarantines but does not run PCI remove/rescan.
3. **Limited fleet visibility** — no scored alerting for Tier-1 patterns; three hosts failed log collection entirely.

**Priority hosts:** `10.30.30.41` > `10.30.30.24` > `10.30.30.20` > `10.30.30.44`

---

## 2. Fleet triage findings

### 2.1 Severity tiers

#### Tier 1 — Critical (VM launch / teardown failures)

| Host | Issue |
|------|-------|
| **10.30.30.24** | QEMU `vfio: Unable to power on device, stuck in D3` (session `7019d9cd-...`); BAR restore + FLR transaction timeouts on `0000:89:00.0` |
| **10.30.30.20** | BAR-restore storm (40+ lines) on `0000:3e:00.0`; transaction timeout; `D3cold→D0` failure |
| **10.30.30.41** | FLR gave up after 65s on `0000:81:00.0`; hundreds of `vfio_pci_core_disable` stack traces (RCU stall / hung task); NVIDIA quirk delays ~3.9s; config-space read timeouts during re-attach |

#### Tier 2 — Hardware / link health

| Host | Issue |
|------|-------|
| **10.30.30.41** | Chronic AER `RxErr` + `BadTLP` on `0000:c3:00.0/1` (Jun 3–8) |
| **10.30.30.44** | Recurring AER `RxErr` on `0000:41:00.0/1` |

#### Tier 3 — Noisy but likely benign

- `Unable to change power state from D0 to D3hot, device inaccessible` on `.0`/`.1` pairs across **.4, .5, .7, .8, .20, .21, .22, .45** and others.
- Occasional single `vfio_bar_restore` (1–2×) — normal FLR recovery.

#### Tier 4 — Monitoring blind spots

- **10.30.30.6, .42, .43** — log collection failed (`Failed to execute`). Treat as infra P0, not “no issues.”

### 2.2 Correlation to known failure modes

These map to the patterns documented in [gpu_passthrough_analysis.md](./gpu_passthrough_analysis.md):

| Observed symptom | Documented cause | Software status |
|------------------|------------------|-----------------|
| `D3cold→D0` / config space inaccessible | IOThread IRQ race, direct root-complex attach, D3cold wake | Patched: no `iothread` on virtio disks; `pcie-root-port`; `d3cold_allowed=0` |
| `stuck in D3` at launch | GPU stuck in low power after bad reset | Partially mitigated: power stabilization + cooldown; needs recovery path |
| BAR-restore storm | FLR / reset recovery loop | Cooldown helps; needs rate-limited quarantine |
| AER `RxErr` / `BadTLP` | Physical link / slot | Not fixable in software — hardware action |
| `D0→D3hot` teardown warning | Benign VFIO release race | **Incorrectly triggers quarantine today** |

---

## 3. Current software behavior

### 3.1 Mitigations already in production

**Power stabilization** (`worker/proxy/qemu/pcie.go`):

- Writes `d3cold_allowed=0` and `power/control=on` at `FetchGPUs` and before each attach.
- Uses virtual `pcie-root-port` per GPU (not direct root-complex attach).
- `gpuPassthroughCooldown = 20s` after VM releases a GPU.
- `gpuPassthroughHealthy()` reads config space before attach; inaccessible → taint.

**Quarantine** (`worker/proxy/qemu/gpu_taint_store.go`, `manager.go`):

- `UnbindGPU` → `quarantineGPU` → `taintDevice` (sets in-memory flag + persists to `gpu_taint.yaml`).
- Tainted GPUs are excluded from `ClaimGPU`; state surfaces via `/info` as `tained: true`.
- External edits to `gpu_taint.yaml` are picked up within ~2s by the taint store watcher.

**Live monitoring** (`worker/daemon/job.go`):

- `watchPCIFailure` runs `dmesg -W` and calls `UnbindGPU` on matches from `filterErrorDmesg`.

### 3.2 Known gaps

| Gap | Impact |
|-----|--------|
| `filterErrorDmesg` matches any `Unable to change power state` | Benign `D0→D3hot` teardown may quarantine healthy GPUs fleet-wide |
| Single `vfio_bar_restore` triggers quarantine | Normal FLR recovery may over-quarantine |
| Missing Tier-1 patterns (`stuck in D3`, FLR timeout, AER storms) | Critical failures may not auto-quarantine |
| `RefreshGPUs()` exists but has no gRPC / mgmt exposure | Recovery requires proxy restart |
| No `RecoverGPU` / `UntaintGPU` RPC | Ops must SSH and edit `gpu_taint.yaml` manually |
| `gpu_passthrough_analysis.md` §4 describes sysfs `remove` in `UnbindGPU` | **Outdated** — current code only quarantines |

---

## 4. Remediation phases

### Phase 0 — Immediate ops (today)

**Goal:** Stop bad GPUs from taking sessions; restore monitoring on blind hosts.

#### 4.0.1 Manually quarantine Tier-1 GPUs

| Host | BDF | Reason |
|------|-----|--------|
| **10.30.30.41** | `0000:81:00.0` | FLR gave up after 65s; RCU stall / `vfio_pci_core_disable` storm |
| **10.30.30.41** | `0000:c3:00.0` (+ `.1` consumer) | Chronic AER `RxErr` / `BadTLP` |
| **10.30.30.24** | `0000:89:00.0` | QEMU `stuck in D3`; BAR restore + transaction timeout |
| **10.30.30.20** | `0000:3e:00.0` | 40+ BAR-restore lines; `D3cold→D0` failure |

**Via mgmt CLI** (from a node with daemon access):

```bash
mgmt gpu unbind <node-name> 0000:81:00.0
```

**Or edit `gpu_taint.yaml`** on the worker proxy host:

```yaml
gpus:
  - id: "0000:81:00.0"
    reason: "FLR timeout + RCU stall (manual quarantine 2026-06-09)"
```

Verify taint propagated: `mgmt gpu list` or `GET /info` → `tained: true` for that BDF.

#### 4.0.2 Recover stuck devices

Run only when no VM holds the GPU (`inuse: false` in `/info`):

```bash
# Per stuck BDF (example: 0000:89:00.0)
echo 1 | sudo tee /sys/bus/pci/devices/0000:89:00.0/remove
echo 1 | sudo tee /sys/bus/pci/rescan
# Re-bind to vfio-pci per host setup script, then restart proxy
# (or call RefreshGPUs once RPC is exposed — Phase 1)
```

Confirm recovery:

```bash
# Config space readable?
sudo dd if=/sys/bus/pci/devices/0000:89:00.0/config bs=4 count=1 2>/dev/null | xxd
# Bound to vfio-pci?
ls -l /sys/bus/pci/drivers/vfio-pci/ | grep 0000:89:00.0
```

Do **not** remove a GPU from `gpu_taint.yaml` until config space is healthy and a soak test passes (Phase 4).

#### 4.0.3 Fix monitoring blind spots

For **10.30.30.6, .42, .43**:

1. Confirm SSH / ansible connectivity and daemon health.
2. Re-run the VFIO `dmesg` grep playbook.
3. Add a watchdog alert if collection fails twice consecutively (Phase 2).

#### 4.0.4 Hardware triage (parallel)

| Host | Action |
|------|--------|
| **.41** | Inspect PCIe slots for `c3:00` and `81:00`; reseat GPU/riser; clear AER after reboot |
| **.44** | Inspect `0000:41:00.0/1` link — recurring `RxErr` suggests physical layer |
| **.24, .20** | If same BDF fails again within 48h after software recovery → treat as hardware |

---

### Phase 1 — Software fixes (1–2 weeks)

**Goal:** Quarantine only real failures; auto-recover where safe; extend detection.

#### 4.1.1 Refine `filterErrorDmesg` (highest impact)

**Files:** `worker/daemon/job.go`, `worker/daemon/job_test.go`

**Narrow `unable_to_change_power_state`:**

- Quarantine only on **wake failures**: `D3cold→D0`, `D3hot→D0`, or lines containing `config space inaccessible`.
- **Ignore** `D0→D3hot` and `D0→D3cold` unless repeated (rate limit below).

**Rate-limit `vfio_bar_restore`:**

- Do not quarantine on a single occurrence.
- Quarantine if ≥3 BAR-restore lines for the same BDF within 60s, or paired with `transaction timeout` / `config space inaccessible`.

**Add Tier-1 patterns:**

| Pattern | Action |
|---------|--------|
| `stuck in D3` (QEMU vfio) | Immediate quarantine |
| `not ready.*after FLR.*giving up` | Immediate quarantine |
| `timed out waiting for pending transaction` | Quarantine if ≥2 in 120s |
| `vfio_pci_core_disable` stack trace burst | Quarantine parent GPU BDF |
| AER `RxErr` / `BadTLP` on same BDF ≥5 in 1h | Quarantine (hardware suspect) |

**Debounce:** Max one `UnbindGPU` per BDF per 10 minutes.

```
dmesg -W line
    → filterErrorDmesg
        → benign D0→D3hot          → ignore
        → Tier-1 / bar_restore storm → debounce OK? → UnbindGPU (quarantine)
```

#### 4.1.2 Post-failure recovery path

**Files:** `worker/proxy/qemu/manager.go`, `worker/proxy/qemu/pci_rescan_linux.go`, new `gpu_recovery_linux.go`

Add `RecoverGPU(gpuID)`:

1. Wait until `claim == nil`.
2. Run `stabilizePassthroughPower` on GPU + consumers.
3. If config still inaccessible → sysfs `remove` + `pciRescan()` + re-bind `vfio-pci`.
4. Call `RefreshGPUs()` to refresh `dev_path`.
5. If `gpuPassthroughHealthy()` passes → log success but **keep taint** until ops manually clears.

**Expose via gRPC and mgmt:**

| RPC / command | Purpose |
|---------------|---------|
| `RefreshGPUs` | Rescan PCI bus and merge vfio-pci devices |
| `RecoverGPU` | Power stabilize + remove/rescan + health check |
| `UntaintGPU` / mgmt `gpu untaint` | Remove entry from `gpu_taint.yaml` |

#### 4.1.3 Adaptive cooldown

**File:** `worker/proxy/qemu/pcie.go`

| Teardown outcome | Cooldown |
|------------------|----------|
| Clean release | 20s (unchanged) |
| BAR-restore storm or FLR timeout in session logs | 120s |
| `stuck in D3` or config inaccessible at attach | 300s + taint |

Extend `VfioPassthroughFailureLog` in `gpu_feedback.go` to classify session severity from proxy/QEMU stderr.

#### 4.1.4 Pre-launch hardening

On attach failure with “stuck in D3”: attempt one `RecoverGPU` before returning error to the scheduler.

#### 4.1.5 Documentation updates

- Update [gpu_passthrough_analysis.md](./gpu_passthrough_analysis.md) §4 (UnbindGPU behavior, `RefreshGPUs`, recovery playbook).
- Keep this plan’s triage table current after each fleet audit.

---

### Phase 2 — Monitoring and alerting (1 week, parallel with Phase 1)

**Goal:** Replace manual grep with scored, actionable alerts.

#### 4.2.1 Fleet VFIO health collection

Per-worker cron or ansible task:

```bash
dmesg -T 2>/dev/null | grep -E 'vfio|AER.*RxErr|BadTLP|stuck in D3|FLR|vfio_bar_restore' \
  | tail -500 > /var/log/vfio-health.log
```

#### 4.2.2 Scoring (last 24h, per host / BDF)

| Score | Condition |
|-------|-----------|
| +10 | `stuck in D3` |
| +10 | FLR gave up |
| +8 | config inaccessible on wake (`D3cold→D0`, `D3hot→D0`) |
| +5 | BAR-restore ≥3 for same BDF |
| +3 | AER `RxErr` / `BadTLP` ≥5 for same BDF |
| +0 | single `D0→D3hot` (informational only) |

**Alert** if host score ≥10 or any single BDF ≥10.

#### 4.2.3 Dashboard visibility

`/info` already exposes `GPU.Tained`. Extend with:

- `taint_reason` from `gpu_taint.yaml`
- Last VFIO failure timestamp per GPU (proxy log or taint store metadata)

#### 4.2.4 Blind-host watchdog

Alert if VFIO health collection fails on any worker two consecutive runs.

---

### Phase 3 — Hardware remediation (ongoing)

| Priority | Host | Work |
|----------|------|------|
| P0 | **.41** | Reseat/replace riser or GPU at `c3:00` and `81:00`; clear AER; 48h soak |
| P1 | **.44** | Same for `41:00` |
| P2 | **.24, .20** | Slot inspection if software recovery fails twice |
| P3 | Fleet | Standardize riser quality; avoid direct root-port wiring (software already enforces `pcie-root-port`) |

**Hardware acceptance:** Zero AER errors over 72h idle + 20 launch/teardown cycles on that slot.

---

### Phase 4 — Validation (after Phase 0–1 deploy)

#### 4.4.1 Per-host checklist

For **.41, .24, .20** and previously noisy hosts **.4, .5, .7, .8**:

- [ ] No `stuck in D3` in dmesg over 50 session cycles
- [ ] Tier-1 BDFs show `tained` in `/info` until manually cleared
- [ ] Benign `D0→D3hot` lines do **not** trigger quarantine
- [ ] Cooldown respected: no back-to-back claim within configured window
- [ ] `gpu_taint.yaml` edits propagate within 2s

#### 4.4.2 Regression tests

**`worker/daemon/job_test.go`:**

| Input | Expected |
|-------|----------|
| `D0→D3hot, device inaccessible` | No trigger |
| `D3cold→D0 config space inaccessible` | Trigger |
| 1× `vfio_bar_restore` | No trigger |
| 3× `vfio_bar_restore` in 30s | Trigger |
| `stuck in D3` | Trigger |

**`worker/proxy/qemu/gpu_feedback_test.go`:** extend for new failure strings.

#### 4.4.3 Rollout order

1. Deploy daemon dmesg filter fix (biggest fleet-wide impact).
2. Deploy proxy recovery + adaptive cooldown.
3. Manual untaint only after `RecoverGPU` + health check passes.
4. Re-run fleet VFIO grep after 1 week; compare Tier-1 counts to baseline.

---

## 5. Work breakdown

| # | Task | Component | Effort |
|---|------|-----------|--------|
| 1 | Narrow `filterErrorDmesg` + debounce | daemon | S |
| 2 | Add Tier-1 dmesg patterns + tests | daemon | S |
| 3 | `RecoverGPU` + PCI remove/rescan | proxy | M |
| 4 | gRPC `RefreshGPUs` / `RecoverGPU` / `UntaintGPU` | proxy + daemon | M |
| 5 | mgmt CLI commands | `worker/daemon/cmd/mgmt` | S |
| 6 | Adaptive cooldown | proxy | S |
| 7 | VFIO health scoring script + alerts | ops / infra | M |
| 8 | Expose `taint_reason` in `/info` | daemon | S |
| 9 | Update `gpu_passthrough_analysis.md` | docs | S |
| 10 | Hardware inspection .41 / .44 | ops | — |

**Recommended first PR:** daemon `filterErrorDmesg` refinement + tests — stops false quarantines across the fleet with minimal risk.

---

## 6. Risk notes

- **Over-quarantine today:** If `watchPCIFailure` is active fleet-wide, the broad `Unable to change power state` rule may have tainted many healthy GPUs on teardown. After deploying the filter fix, audit `gpu_taint.yaml` on all nodes and clear stale entries where config space reads clean.
- **`.41` RCU stall:** Software quarantine prevents session impact but does not eliminate kernel hang risk; treat as hardware-critical until the slot is validated.
- **`RefreshGPUs` has no RPC today:** Recovery currently requires proxy restart until ticket #4 lands.

---

## 7. Recommended execution order

```
Today:     Phase 0 — quarantine .41 / .24 / .20; fix .6 / .42 / .43 monitoring
Week 1:    Phase 1.1–1.2 — dmesg filter + recovery RPC
Week 1–2:  Phase 1.3–1.5 + Phase 2 monitoring
Parallel:  Phase 3 hardware on .41 / .44
Week 3:    Phase 4 validation; untaint only proven-healthy GPUs
```

---

## 8. Revision history

| Date | Change |
|------|--------|
| 2026-06-09 | Initial plan from fleet VFIO `dmesg` triage (hosts .41, .24, .20, .44, monitoring gaps on .6/.42/.43) |
