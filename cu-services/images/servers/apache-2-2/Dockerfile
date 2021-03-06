FROM cloudunit/base-jessie

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
#RUN groupadd -r www-data && useradd -r --create-home -g www-data www-data

ENV HTTPD_PREFIX /usr/local/apache2
ENV PATH $HTTPD_PREFIX/bin:$PATH
RUN mkdir -p "$HTTPD_PREFIX" \
	&& chown www-data:www-data "$HTTPD_PREFIX"
WORKDIR $HTTPD_PREFIX

# install httpd runtime dependencies
# https://httpd.apache.org/docs/2.4/install.html#requirements
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		libapr1 \
		libaprutil1 \
		libaprutil1-ldap \
		libapr1-dev \
		libaprutil1-dev \
		libpcre++0 \
		libssl1.0.0 \
	&& rm -r /var/lib/apt/lists/*

ENV HTTPD_VERSION 2.2.31
ENV HTTPD_SHA1 e3b55387112206307ba76526820a2627472f3787
ENV HTTPD_BZ2_URL https://www.apache.org/dist/httpd/httpd-$HTTPD_VERSION.tar.bz2

RUN set -x \
	&& buildDeps=' \
		bzip2 \
		ca-certificates \
		gcc \
		libpcre++-dev \
		libssl-dev \
		make \
		wget \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& rm -r /var/lib/apt/lists/* \
	\
	&& wget -O httpd.tar.bz2 "$HTTPD_BZ2_URL" \
	&& echo "$HTTPD_SHA1 *httpd.tar.bz2" | sha1sum -c - \
# see https://httpd.apache.org/download.cgi#verify
	&& wget -O httpd.tar.bz2.asc "$HTTPD_BZ2_URL.asc" \
	&& export GNUPGHOME="$(mktemp -d)" \
	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B1B96F45DFBDCCF974019235193F180AB55D9977 \
	&& gpg --batch --verify httpd.tar.bz2.asc httpd.tar.bz2 \
	&& rm -r "$GNUPGHOME" httpd.tar.bz2.asc \
	\
	&& mkdir -p src \
	&& tar -xvf httpd.tar.bz2 -C src --strip-components=1 \
	&& rm httpd.tar.bz2 \
	&& cd src \
	\
	&& ./configure \
		--prefix="$HTTPD_PREFIX" \
# https://httpd.apache.org/docs/2.2/programs/configure.html
# Caveat: --enable-mods-shared=all does not actually build all modules. To build all modules then, one might use:
		--enable-mods-shared='all ssl ldap cache proxy authn_alias mem_cache file_cache authnz_ldap charset_lite dav_lock disk_cache' \
	&& make -j"$(nproc)" \
	&& make install \
	\
	&& cd .. \
	&& rm -r src \
	\
	&& sed -ri \
		-e 's!^(\s*CustomLog)\s+\S+!\1 /proc/self/fd/1!g' \
		-e 's!^(\s*ErrorLog)\s+\S+!\1 /proc/self/fd/2!g' \
		"$HTTPD_PREFIX/conf/httpd.conf" \
	\
	&& apt-get purge -y --auto-remove $buildDeps

COPY httpd-foreground /usr/local/bin/

## CLOUDUNIT :: BEGINNING
ENV CU_SOFTWARE UNDEF
ENV CU_SERVER_MANAGER_PATH UNDEF
ENV CU_SERVER_MANAGER_PORT 80
ENV CU_SERVER_PORT 80
ENV CU_SERVER_RESTART_POST_CREDENTIALS true
ENV CU_DEFAULT_LOG_FILE access.log
ENV CU_LOGS STDOUT
ENV CU_DEFAULT_JAVA_RELEASE "jdk1.8.0_25"
ENV JAVA_HOME /opt/cloudunit/java/$CU_DEFAULT_JAVA_RELEASE
ENV JAVA_OPTS "-Dfile.encoding=UTF-8 -Xms512m -Xmx512m -XX:MaxPermSize=256m"

# add custom scripts
ADD scripts /opt/cloudunit/scripts
RUN chmod +x /opt/cloudunit/scripts/*

## CLOUDUNIT :: END

EXPOSE 80
CMD ["httpd-foreground"]


