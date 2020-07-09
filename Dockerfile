FROM openjdk:11 

ENV CANTALOUPE_VERSION=4.1.6
ENV GEM_PATH=/var/lib/gems/2.5.0:/home/cantaloupe/.gem/ruby/2.5.0:/usr/lib/x86_64-linux-gnu/rubygems-integration/2.5.0:/usr/share/rubygems-integration/2.5.0:/usr/share/rubygems-integration/all

EXPOSE 8182

VOLUME /imageroot

# Update packages and install tools
RUN apt-get update -qy && apt-get dist-upgrade -qy && \
    apt-get install -qy --no-install-recommends curl imagemagick \
    libopenjp2-tools ffmpeg unzip default-jre-headless && \
    apt-get install -y jruby && \
    apt-get -qqy autoremove && apt-get -qqy autoclean

# Run non privileged
RUN adduser --system cantaloupe
ADD https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip /cantaloupe/cantaloupe.zip
RUN /bin/sh -c 'unzip -j /cantaloupe/cantaloupe.zip cantaloupe-${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.war -d /cantaloupe'
RUN /bin/sh -c 'rm -f /cantaloupe/cantaloupe.zip'

ENV BUNDLE_GEMFILE=/cantaloupe/Gemfile \
BUNDLE_JOBS=4
RUN gem install bundler

COPY Gemfile* cantaloupe/
RUN  bash -l -c "bundle check || bundle install"

COPY delegates.rb cantaloupe
COPY cantaloupe.properties cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R cantaloupe /cantaloupe /var/log/cantaloupe /var/cache/cantaloupe 

USER cantaloupe
WORKDIR /cantaloupe
CMD ["/bin/sh", "-c",  "java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties -jar /cantaloupe/cantaloupe-$CANTALOUPE_VERSION.war"]
