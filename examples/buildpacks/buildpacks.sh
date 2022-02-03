#!/bin/bash
set -euo pipefail

# Define variables.
GIT_ROOT=$(git rev-parse --show-toplevel)
DEFAULT_REPOSITORY=$(xxd -l 16 -c 16 -p < /dev/random)
: "${REGISTRY:=ttl.sh}"
: "${REPOSITORY:=$REGISTRY/$DEFAULT_REPOSITORY}"
C_GREEN='\033[32m'
C_RESET_ALL='\033[0m'

# Install shared tasks.
kubectl apply -f "${GIT_ROOT}"/platform/vendor/tekton/catalog/main/task/git-clone/0.4/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/buildpacks/tekton-integration/main/task/buildpacks/0.4/buildpacks.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/buildpacks-phases/0.2/buildpacks-phases.yaml

# Install shared pipeline.
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/pipeline/buildpacks/0.1/buildpacks.yaml

# Install the buildpacks pipelinerun.
echo -e "${C_GREEN}Creating a buildpacks pipelinerun: REPOSITORY=${REPOSITORY}${C_RESET_ALL}"
pushd "${GIT_ROOT}"
cue -t "repository=${REPOSITORY}" apply ./examples/buildpacks | kubectl apply -f -
cue -t "repository=${REPOSITORY}" create ./examples/buildpacks | kubectl create -f -
popd
tkn pipelinerun describe --last