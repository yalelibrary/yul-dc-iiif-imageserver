FROM openjdk:11

ENV CANTALOUPE_VERSION=5.0.6
ENV JRUBY_VERSION=9.3.0.0

EXPOSE 8182

VOLUME /imageroot

# Fix Java DNS TTL
RUN echo "\nnetworkaddress.cache.ttl=120" >> /usr/local/openjdk-11/conf/security/java.security

# Update packages and install tools
RUN apt-get -qq update -y && \
    apt-get -qq install -y --no-install-recommends curl imagemagick \
    libopenjp2-tools ffmpeg unzip default-jre-headless vim && \
    apt-get -qqy autoremove && apt-get -qqy autoclean
RUN mkdir /cantaloupe_temp

RUN curl https://repo1.maven.org/maven2/org/jruby/jruby-dist/${JRUBY_VERSION}/jruby-dist-${JRUBY_VERSION}-bin.tar.gz > jruby.tgz && tar -xvzf jruby.tgz && rm jruby.tgz

RUN ln -s /jruby-${JRUBY_VERSION} /jruby
ENV PATH="/jruby/ruby/gems/shared/gems/bundler-2.2.14/exe:${PATH}"
ENV PATH="/jruby/bin:${PATH}"
# Run non privileged
RUN adduser --system cantaloupe
ADD https://github.com/K8Sewell/cantaloupe/archive/refs/tags/v${CANTALOUPE_VERSION}.zip /cantaloupe/cantaloupe.zip
RUN /bin/sh -c 'unzip -j /cantaloupe/cantaloupe.zip cantaloupe-${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.jar -d /cantaloupe'
RUN /bin/sh -c 'rm -f /cantaloupe/cantaloupe.zip'
RUN gem install --no-doc honeybadger
COPY delegates.rb cantaloupe
COPY cantaloupe.properties cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R cantaloupe /cantaloupe /var/log/cantaloupe /var/cache/cantaloupe 
ENV GEM_HOME=/jruby/lib/ruby/gems/shared:$GEM_HOME

USER cantaloupe
WORKDIR /cantaloupe
USER root
COPY ops/boot.sh /boot.sh
HEALTHCHECK CMD curl --fail http://localhost:8182/ || exit 1
CMD ["/boot.sh"]
