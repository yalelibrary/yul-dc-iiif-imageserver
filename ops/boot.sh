#!/bin/bash -ex
if [ ! -z "$DYNATRACE_TOKEN" ];then
  curl -Ls -H "Authorization: Api-Token ${DYNATRACE_TOKEN}" 'https://nhd42358.live.dynatrace.com/api/v1/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default' > installer.sh

<<<<<<< HEAD
  whoami
  /bin/sh installer.sh --set-app-log-content-access=true --set-infra-only=true --set-host-group=DC --set-host-name=${CLUSTER_NAME}-iiif-image NON_ROOT_MODE=0 2>&1 & 
fi
id cantaloupe
su cantaloupe -s /bin/sh /bin/sh -c  'java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties -jar /cantaloupe/cantaloupe-$CANTALOUPE_VERSION.war'
=======
  /bin/sh installer.sh --set-app-log-content-access=true --set-infra-only=true --set-host-group=DC --set-host-name=${CLUSTER_NAME}-iiif-image 2>&1 & 
fi
/bin/sh -c  'java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties -jar /cantaloupe/cantaloupe-$CANTALOUPE_VERSION.war'
>>>>>>> master

