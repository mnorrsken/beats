#!/bin/bash
# GITHUB_TOKEN is required
# PLATFORMS is required
set -e
PDIR=$(pwd)
export GOPATH=${PDIR}/go
export PATH=${PATH}:/usr/local/go/bin:${GOPATH}/bin
UPLOAD=${PDIR}/upload-all.sh
mkdir -p ${GOPATH}
GOVER=$(go version)

curl https://api.github.com/repos/elastic/beats/releases | jq '.[] | .tag_name' -r > es_tags.txt
curl https://api.github.com/repos/mnorrsken/beats/releases | jq '.[] | .tag_name' -r > mn_tags.txt
build_tags=$(diff mn_tags.txt es_tags.txt | grep -E '^> v(7\.([8-9]|[1-9][0-9]+)\.|[89]\.)' | cut -c3- | sort -n)
for tag in $build_tags; do
    cd ${PDIR}
    chmod -R +w beats || true
    rm -rf beats || true
    git clone https://github.com/elastic/beats.git
    cd ${PDIR}/beats
    git checkout $tag
    cd ${PDIR}/beats/filebeat
    make release
    cd ${PDIR}/beats/metricbeat
    make release

    github-release release \
        --user mnorrsken \
        --repo beats \
        --tag $tag \
        --name "Beats $tag" \
        --description "Built from beats https://github.com/elastic/beats/tree/$tag with $GOVER" \

    cd ${PDIR}
    $UPLOAD beats/filebeat/build/distributions $tag
    $UPLOAD beats/metricbeat/build/distributions $tag
done
