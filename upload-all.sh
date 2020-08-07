#!/bin/bash
set -e
cd $1
for f in *; do
    github-release upload \
    --user mnorrsken \
    --repo beats \
    --tag $2 \
    --name "$f" \
    --file "$f"
done
