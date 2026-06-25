FROM amazoncorretto:11-alpine

ENV CANTALOUPE_VERSION=5.0.6
ENV JRUBY_VERSION=9.3.0.0

# remove expose and healthcheck for 8182 post migration
EXPOSE 8182
EXPOSE 8183

VOLUME /imageroot

# Fix Java DNS TTL
RUN echo "\nnetworkaddress.cache.ttl=120" >> /usr/lib/jvm/default-jvm/conf/security/java.security

# Update packages and install tools
RUN apk update && \
    apk add --no-cache bash curl imagemagick ffmpeg openjpeg-tools unzip vim && \
    rm -rf /var/cache/apk/*
RUN mkdir /cantaloupe_temp

RUN curl https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz > jruby.tgz && tar -xvzf jruby.tgz && rm jruby.tgz

RUN ln -s /jruby-${JRUBY_VERSION} /jruby
ENV PATH="/jruby/ruby/gems/shared/gems/bundler-2.2.14/exe:${PATH}"
ENV PATH="/jruby/bin:${PATH}"
# Run non privileged
RUN adduser --system cantaloupe
ADD https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip /cantaloupe/cantaloupe.zip
RUN /bin/sh -c 'unzip -j /cantaloupe/cantaloupe.zip cantaloupe-${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.jar -d /cantaloupe'
RUN /bin/sh -c 'rm -f /cantaloupe/cantaloupe.zip'
RUN gem install --no-doc honeybadger
COPY delegates.rb cantaloupe
COPY cantaloupe.properties cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R cantaloupe /cantaloupe /var/log/cantaloupe /var/cache/cantaloupe 
ENV GEM_HOME=/jruby/lib/ruby/gems/shared:$GEM_HOME

# Disable deprecated library
ENV JAVA_TOOL_OPTIONS="-Dcom.sun.media.jai.disableMediaLib=true"

USER cantaloupe
WORKDIR /cantaloupe
USER root
COPY ops/boot.sh /boot.sh
HEALTHCHECK CMD curl --fail http://localhost:8182/ || exit 1
CMD ["/boot.sh"]
