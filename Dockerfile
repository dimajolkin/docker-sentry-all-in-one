#FROM sentry:9.1-onbuild
FROM ubuntu:18.04

ENV SENTRY_REDIS_HOST 0.0.0.0
ENV SENTRY_SECRET_KEY "i2d!-duqi%zuf*4xc3=xf6k6+x9%olbyssafxah%4^v1(^(-nb"
ENV C_FORCE_ROOT 1


ENV PG_MAJOR 10
ENV PGDATA /var/lib/postgresql/data
ENV PATH $PATH:/usr/lib/postgresql/$PG_MAJOR/bin

RUN apt update
#redis
RUN apt install -y redis-server

# supervisord
RUN mkdir -p /var/log/supervisor
RUN apt-get install -y supervisor

# install postgres
RUN apt-get install -y postgresql postgresql-contrib libpq-dev gosu

# install sentry
RUN apt-get install -y build-essential python-dev python-virtualenv python3
RUN apt-get install -y python-pip
# sentry & pg driver
RUN pip install psycopg2
RUN pip install sentry

# script to execute postgresql in foreground mode
ADD conf/run_postgres.sh /usr/local/bin/run_postgresql.sh
RUN chmod +x /usr/local/bin/run_postgresql.sh


#configs



#postgres configuration
RUN set -eux; \
	dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; \
	cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; \
	ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; \
	sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; \
	grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

RUN cp /usr/share/postgresql/postgresql.conf.sample /var/lib/postgresql/$PG_MAJOR/main/postgresql.conf

RUN  su postgres -c "/usr/lib/postgresql/10/bin/pg_ctl initdb"
RUN touch $PGDATA/pg_hba.conf && echo "host all all all trust" >> "$PGDATA/pg_hba.conf"

ENV SENTRY_POSTGRES_HOST 127.0.0.1
ENV SENTRY_DB_NAME 'sentry'
ENV SENTRY_DB_USER 'postgres'
ENV SENTRY_DB_PASSWORD 'postgres'
ENV SENTRY_POSTGRES_PORT '5432'

ENV AUTH_LOGIN='user1'
ENV AUTH_PASWORD='fakepassword'
ENV AUTH_EMAIL='your@email.com'

ENV SENTRY_CONF /etc/sentry
RUN sentry init $SENTRY_CONF
ADD conf/sentry.conf.py $SENTRY_CONF/sentry.conf.py
ADD conf/bootstrap.py /etc/sentry/bootstrap.py

RUN su - postgres -c "PGDATA=$PGDATA /usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl -w start" && \
  sleep 10 && \
  redis-server --daemonize yes && \
  su postgres sh -c "psql -c \"create database sentry;\" " && \
  su postgres sh -c "psql -c \"ALTER USER postgres WITH PASSWORD 'postgres';\" " && \
  su postgres sh -c "psql -c \"ALTER ROLE postgres SUPERUSER;\" " && \
  sentry upgrade --noinput
  #cat /sentry.py | sentry shell
  #sentry createuser --email $AUTH_LOGIN --password=$AUTH_PASWORD --superuser
  #su postgres sh -c "psql -c \"\c sentry; update public.auth_user set email = 'user1@example.com' where username = '$AUTH_LOGIN';\" "


#RUN su - postgres -c "PGDATA=$PGDATA /usr/lib/postgresql/$PG_MAJOR/bin/pg_ctl -w start" && \

ADD conf/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ports for sentry
EXPOSE 9000

# run supervisord in foreground
CMD ["/usr/bin/supervisord", "--nodaemon"]