---
name: apply_manifest
description: Interactively verify and apply a k8s-manifests config to GCP or Nebius clusters
argument-hint: "[config_file]"
allowed-tools: Bash, Read, Glob, Grep, Agent, AskUserQuestion
---

# Apply Manifest

Interactively verify and apply a k8s-manifests config to a Kubernetes cluster on GCP or Nebius.

## Arguments

**CRITICAL**: Arguments come ONLY from the user's message — the `$ARGUMENTS` string. The assistant MUST NOT inject, add, or fabricate any arguments that the user did not explicitly provide. No exceptions.

Parse the following from `$ARGUMENTS`:
- **config_file** (optional): Path to a k8s-manifests config YAML. Can be:
  - An absolute path
  - A relative path (resolve against cwd, then `~/repos/k8s-manifests/configs/`)
  - A bare filename — search recursively under `~/repos/k8s-manifests/configs/`

## Verification Stages

**IMPORTANT**: All stages are interactive — you MUST present the auto-detected or derived value to the user and ask for explicit confirmation before moving to the next stage. Do NOT silently auto-confirm. A stage may be skipped (no confirmation needed) only when the user explicitly provided the value as input to the skill invocation and it matches what the config contains (this counts as pre-confirmed).

### Stage 1: Which config to run

- If `config_file` was provided as an argument, use it.
- If there is exactly one obvious config being discussed in the conversation context, use that automatically.
- Otherwise, ask the user which config to apply.

Resolve the config path:
1. If absolute path and exists, use it.
2. If relative path, try as-is from cwd, then under `~/repos/k8s-manifests/configs/`.
3. If bare filename, search recursively under `~/repos/k8s-manifests/configs/`. If multiple matches, show them and ask the user to pick.

Read the resolved config file.

Verify the config's `job_name` field matches the file's basename (without the `.yaml`/`.yml` extension). Example: `cybergym-v18-qwen3-4b-async-minitest.yaml` must contain `job_name: "cybergym-v18-qwen3-4b-async-minitest"`. If they differ, **stop** and ask the user which one to keep — mismatched filename/job_name is almost always a copy-paste leftover from duplicating a config, and it silently writes checkpoints and W&B runs under the old experiment's identity.

### Stage 2: Cloud provider

Determine the cloud provider from the config:
- If the config path or content contains "nebius" -> **Nebius**
- If the config references GCP-specific fields (e.g., `provisioning_model`, GKE cluster names) -> **GCP**
- If ambiguous, ask the user to confirm: "GCP or Nebius?"

### Stage 3: GPU type

Read the `gpu_type` field from the config. Map it using this table:

| Short name | Accelerator name |
|---|---|
| A100 | nvidia-a100-80gb |
| B200 | nvidia-b200 |
| H100 | nvidia-h100-80gb |
| H100-Mega | nvidia-h100-mega-80gb |
| H200 | nvidia-h200-141gb |

If the config does not contain a `gpu_type` field, ask the user which GPU type they need.

### Stage 4: Check availability

#### GCP

Use corma-cli to find zones and clusters with the GPU:

```bash
uv run --project ~/repos/corma-cli ccli gcp-get-dws-gpus --gpu <SHORT_GPU_NAME> --nodes 1
```

This queries zones, finds GKE clusters, and submits a provisioning request. Once it succeeds, it outputs the cluster name, zone, and context. Then get credentials:

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --location=<LOCATION> --project <PROJECT> --quiet
```

The kubectl context is: `gke_<PROJECT>_<LOCATION>_<CLUSTER_NAME>`

#### Nebius

Nebius has two contexts mapped by GPU type:
- **H200** -> `nebius-mk8s-h200-cluster`
- **B200** -> `nebius-mk8s-b200-cluster`

Pick the context that matches the GPU type from the config.

Check node availability by counting **free** (unused) GPU nodes — not just total nodes. A node is free if its GPU allocation is 0. Use:
```bash
kubectl --context <NEBIUS_CONTEXT> get nodes -l 'nebius.com/gpu-name=<GPU_SHORT_NAME>' --no-headers 2>/dev/null | while read name rest; do gpu=$(kubectl --context <NEBIUS_CONTEXT> describe node "$name" 2>/dev/null | grep 'nvidia.com/gpu' | tail -1 | awk '{print $2}'); echo "$gpu"; done | awk '{if($1=="0") free++; total++} END{print free" free out of "total" total"}'
```

**IMPORTANT**: Do NOT just count total nodes — you MUST check how many are actually free (0 GPUs allocated). Report both free and total counts.

Compare the number of free nodes against the config's `num_nodes`. If not enough free nodes, inform the user but ask whether to proceed anyway (jobs can queue and wait for resources on Nebius).

### Stage 5: Verify commit hashes

Find all `commit` fields in the config (e.g., `verl.commit`, `slime.commit`, `rl_env.commit`, `oai_eval.commit`, etc.). For each commit:

1. Verify the SHA is exactly 7 hex characters (`[0-9a-f]{7}`). If not, **stop** and report the invalid value. Explain that commit SHAs must be exactly 7 characters because Docker image names are automatically inferred from them.
2. Print a summary table of all commits with their descriptions. For each commit, resolve the repo path using the mapping below and fetch the description:

   **Repo mapping** (sibling directories of k8s-manifests):
   | Config field | Local repo path |
   |---|---|
   | `slime.commit` | `~/repos/corma-slime` |
   | `rl_env.commit` | `~/repos/rl_env` |
   | `verl.commit` | `~/repos/corma-verl` |

   For each commit, run:
   ```bash
   git -C <repo_path> log --oneline -1 <COMMIT_SHA>
   ```
   If the repo isn't available locally or the commit isn't found, just show the SHA.
3. Ask the user to confirm the commits look correct.

### Stage 6: Check for existing experiments on W&B

Before applying, check if an experiment with the same `job_name` already exists on Weights & Biases. The `project_name` field in the config maps to the W&B project, and `job_name` maps to the W&B group.

Use the wandb MCP tool to search for existing runs:

```
query_wandb_tool: search for runs in project "<project_name>" with group "<job_name>"
```

Or use the CLI:

```bash
wandb runs --project <project_name> --filter "group=<job_name>" 2>/dev/null | head -5
```

If runs with the same group name exist:
- Warn the user that applying this config will **resume a previous training run** because checkpoints from the previous experiment will be found in GCS under the same `job_name` path.
- Ask: "An experiment with job_name '<job_name>' already exists in W&B project '<project_name>'. Applying will resume training from the last checkpoint. Is this intentional?"
- **If no match found**: This is a fresh experiment. Proceed without warning.

## Apply

Once all stages pass (or are skipped), render and apply:

```bash
cd ~/repos/k8s-manifests && uv run scripts/render_config.py <CONFIG_PATH> --apply --context <KUBECTL_CONTEXT>
```

## Post-apply summary

After successful apply, show the user:
- **Config**: path to the config file applied
- **Cloud provider**: GCP or Nebius
- **Context**: the kubectl context used
- **JobSet name**: extract from the render/apply output or from the config's `job_name` field
- **GPU type**: the GPU used
- **Num nodes**: from the config if available

## Error handling

- If no zones have the requested GPU (GCP), tell the user and suggest trying a different GPU type.
- If no running GKE clusters exist in GPU zones (GCP), tell the user.
- If the render/apply fails, show the full error output so the user can debug.
- If gcloud auth is needed, tell the user to run `gcloud auth login` first.
