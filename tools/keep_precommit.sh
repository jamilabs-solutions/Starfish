#!/usr/bin/env bash
exec python3 -I "$(git rev-parse --show-toplevel)/tools/keep.py" precommit