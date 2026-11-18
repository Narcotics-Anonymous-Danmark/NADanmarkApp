#!/usr/bin/env bash
# Runs the Patrol tests on the CI emulator, retrying once.
#
# Lives in a file because reactivecircus/android-emulator-runner executes each
# line of its `script:` input separately with /usr/bin/sh (dash): no pipefail,
# and no multi-line loops.
#
# Usage: e2e-android.sh <adb device id>
set -uo pipefail

device="${1:?usage: e2e-android.sh <adb device id>}"

adb devices

attempt=1
until ./bin/na test e2e --device "$device" --coverage; do
  if [ "$attempt" -ge 2 ]; then
    echo "::error::Patrol tests failed after $attempt attempts"
    exit 1
  fi
  attempt=$((attempt + 1))
  echo "::warning::Patrol tests failed, retrying (attempt $attempt of 2)"
  adb -s "$device" shell am force-stop dk.nadanmark.app || true
done
