#!/bin/bash
set -eo pipefail

# This script builds and validates Kustomize manifests for changed directories.
# It expects a list of space-separated directory paths as the first argument.

CHANGED_DIRS=$1
REPORT_FILE="pr-validation-report.md"

echo "## PR Validation Report" > "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

HAS_ERRORS=false

# Helper to find the nearest directory containing a kustomization file
find_kustomization_root() {
  local dir="$1"
  # Trim trailing slashes
  dir="${dir%/}"
  while [[ "$dir" != "." && "$dir" != "/" && -n "$dir" ]]; do
    if [ -f "$dir/kustomization.yaml" ] || [ -f "$dir/Kustomization" ]; then
      echo "$dir"
      return 0
    fi
    dir=$(dirname "$dir")
  done
  # Special case for root
  if [ -f "kustomization.yaml" ] || [ -f "Kustomization" ]; then
    echo "."
    return 0
  fi
  return 1
}

# Identify all unique kustomization roots for changed files
KUSTOMIZE_ROOTS=""
for dir in $CHANGED_DIRS; do
  # Skip hidden directories like .github, .github/workflows, etc.
  if [[ "$dir" == .* ]]; then
    continue
  fi

  ROOT=$(find_kustomization_root "$dir") || true
  if [ -n "$ROOT" ]; then
    # Add to list if not already there (simple de-duplication)
    if [[ ! " $KUSTOMIZE_ROOTS " =~ " $ROOT " ]]; then
      KUSTOMIZE_ROOTS="$KUSTOMIZE_ROOTS $ROOT"
    fi
  fi
done

if [ -z "$KUSTOMIZE_ROOTS" ]; then
  echo "No Kustomize roots found for changed files." >> "$REPORT_FILE"
fi

for dir in $KUSTOMIZE_ROOTS; do
  echo "### Service: \`$dir\`" >> "$REPORT_FILE"
  echo "" >> "$REPORT_FILE"

  # Build PR manifest
  if ! kustomize build "$dir" --enable-helm > pr-manifest.yaml 2> build-error.log; then
    echo "❌ **Build Failed**" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    cat build-error.log >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    HAS_ERRORS=true
    continue
  fi


  # Static Validation
  echo "#### Static Analysis" >> "$REPORT_FILE"

  # Kubeconform (Schema Validation)
  echo "Checking schema with kubeconform..."
  if ! kubeconform -summary -ignore-missing-schemas -kubernetes-version 1.35.0 pr-manifest.yaml > kc-output.log 2>&1; then
    echo "❌ **Kubeconform Validation Failed**" >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    cat kc-output.log >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    HAS_ERRORS=true
  else
    echo "✅ Kubernetes schema validation passed." >> "$REPORT_FILE"
  fi

  # Pluto (Deprecation Detection)
  echo "Checking for deprecated APIs with pluto..."
  # pluto detect returns non-zero if it finds deprecated APIs that are removed in the target version
  if pluto detect pr-manifest.yaml -o markdown > pluto-output.log 2> pluto-error.log; then
    echo "✅ No deprecated APIs detected." >> "$REPORT_FILE"
  else
    if [ -s pluto-output.log ]; then
      echo "❌ **Pluto Detected Deprecated/Removed APIs**" >> "$REPORT_FILE"
      cat pluto-output.log >> "$REPORT_FILE"
      HAS_ERRORS=true
    else
       echo "❌ **Pluto Detection Failed (Error)**" >> "$REPORT_FILE"
       echo '```' >> "$REPORT_FILE"
       cat pluto-error.log >> "$REPORT_FILE"
       echo '```' >> "$REPORT_FILE"
       HAS_ERRORS=true
    fi
  fi

  # Kube-linter (Best Practices - Warning only, logs only)
  echo "Running kube-linter (warnings only in logs)..."
  kube-linter lint pr-manifest.yaml || true

  echo "" >> "$REPORT_FILE"

  # Compare with main branch

  echo "#### Manifest Diffs" >> "$REPORT_FILE"
  
  # Ensure we have the latest origin/main
  git fetch origin main --quiet || true
  
  if git checkout origin/main -- "$dir" 2>/dev/null; then
    if kustomize build "$dir" --enable-helm > base-manifest.yaml 2>/dev/null; then
      # Restore PR state immediately
      git checkout HEAD -- "$dir" 2>/dev/null
      
      # Use a temporary file for diff to avoid subshell issues with set -e
      dyff between --color off base-manifest.yaml pr-manifest.yaml > diff-output.log 2>&1 || true
      DIFF_OUTPUT=$(cat diff-output.log)
      
      if [ -z "$DIFF_OUTPUT" ]; then
        echo "No changes in generated manifests." >> "$REPORT_FILE"
      else
        echo '<details open><summary>Click to view diff</summary>' >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo "$DIFF_OUTPUT" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        echo '</details>' >> "$REPORT_FILE"
      fi
    else
      git checkout HEAD -- "$dir" 2>/dev/null
      echo "Unable to build base manifest (likely new service or build error in main)." >> "$REPORT_FILE"
    fi
  else
    echo "New service detected. Full manifest in diff." >> "$REPORT_FILE"
    echo '<details><summary>Click to view full manifest</summary>' >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo '```yaml' >> "$REPORT_FILE"
    cat pr-manifest.yaml >> "$REPORT_FILE"
    echo '```' >> "$REPORT_FILE"
    echo '</details>' >> "$REPORT_FILE"
  fi
  echo "" >> "$REPORT_FILE"
done

if [ "$HAS_ERRORS" = true ]; then
  echo "Validation failed for one or more services."
  exit 1
fi

