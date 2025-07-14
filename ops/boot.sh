#!/bin/bash -ex
su cantaloupe -s /bin/sh /bin/sh -c  "GEM_PATH=/jruby/lib/ruby/gems/shared java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties ${IIIF_JAVA_OPTS} -jar /cantaloupe/cantaloupe-$CANTALOUPE_VERSION.jar"

