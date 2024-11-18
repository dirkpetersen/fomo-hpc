#!/bin/bash

# Configure FOMO-HPC 
set -e

export FOMO_ROOT="$(cd -- "$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}")")" &> /dev/null && pwd)"

${FOMO_ROOT}/bin/fomo-config
