#!/bin/bash

set -o pipefail
set -e
set -x

# Check source files for copyright notices

options=(
  -E # Use extended regexps
  -I # Exclude binary files
  -L # Show files that don't have a match
  'Copyright © [0-9]{4}.* Optimove. All rights reserved.'
)

git grep "${options[@]}" -- \
  '*.'{h,m,mm,swift} \
  ':(exclude)**/third_party/**' \
  ':(exclude)scripts/**'
if [[ $? == 0 ]]; then
  echo "ERROR: Missing copyright notices in the files above. Please fix."
  exit 1
fi
