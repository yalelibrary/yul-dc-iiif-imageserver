FROM openjdk:11 

ENV CANTALOUPE_VERSION=4.1.6

EXPOSE 8182

VOLUME /imageroot

# Update packages and install tools
RUN apt-get update -qy && apt-get dist-upgrade -qy && \
    apt-get install -qy --no-install-recommends curl imagemagick \
    libopenjp2-tools ffmpeg unzip default-jre-headless && \
    apt-get -qqy autoremove && apt-get -qqy autoclean && \
    apt-get install -y jruby && \
    apt-get install sudo

# Run non privileged
RUN adduser --system cantaloupe
ADD https://github.com/cantaloupe-project/cantaloupe/releases/download/v${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.zip /cantaloupe/cantaloupe.zip
RUN /bin/sh -c 'unzip -j /cantaloupe/cantaloupe.zip cantaloupe-${CANTALOUPE_VERSION}/cantaloupe-${CANTALOUPE_VERSION}.war -d /cantaloupe'
RUN /bin/sh -c 'rm -f /cantaloupe/cantaloupe.zip'

ENV BUNDLE_GEMFILE=cantaloupe/Gemfile \
BUNDLE_JOBS=4
# RUN jruby -S gem list
RUN jruby -S gem install bundler



COPY Gemfile* cantaloupe/
RUN  bash -l -c "bundle check || bundle install"
# RUN jruby -v
# RUN bundle info honeybadger
RUN jruby -S gem list

COPY delegates.rb cantaloupe
COPY cantaloupe.properties cantaloupe

RUN mkdir -p /var/log/cantaloupe /var/cache/cantaloupe \
    && chown -R cantaloupe /cantaloupe /var/log/cantaloupe /var/cache/cantaloupe 

USER cantaloupe
WORKDIR /cantaloupe
CMD ["/bin/sh", "-c",  "java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties -jar /cantaloupe/cantaloupe-$CANTALOUPE_VERSION.war"]
