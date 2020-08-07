#!/bin/bash
# GITHUB_TOKEN is required
# PLATFORMS is required
# temp dir shenanigans beacause of go mod making stuff readonly
set -e
PDIR=$(pwd)
TMPHOME=$(mktemp -d --suffix _beats)
export GOPATH=${TMPHOME}/go
export PATH=${PATH}:/usr/local/go/bin:${GOPATH}/bin
UPLOAD=${PDIR}/upload-all.sh
mkdir -p ${GOPATH}
GOVER=$(go version)
cd ${TMPHOME}
curl https://api.github.com/repos/elastic/beats/releases | jq '.[] | .tag_name' -r | sort -n > es_tags.txt
curl https://api.github.com/repos/mnorrsken/beats/releases | jq '.[] | .tag_name' -r | sort -n > mn_tags.txt
build_tags=$(diff mn_tags.txt es_tags.txt | grep -E '^> v(7\.([8-9]|[1-9][0-9]+)\.|[89]\.)' | cut -c3- | sort -n)
for tag in $build_tags; do
    cd ${TMPHOME}
    git clone https://github.com/elastic/beats.git
    cd ${TMPHOME}/beats
    git checkout $tag
    cd ${TMPHOME}/beats/filebeat
    make release
    cd ${TMPHOME}/beats/metricbeat
    make release

    github-release release \
        --user mnorrsken \
        --repo beats \
        --tag $tag \
        --name "Beats $tag" \
        --description "Built from beats https://github.com/elastic/beats/tree/$tag with $GOVER" \

    $UPLOAD ${TMPHOME}beats/filebeat/build/distributions $tag
    $UPLOAD ${TMPHOME}beats/metricbeat/build/distributions $tag
done
rm -rf ${TMPHOME} || true
