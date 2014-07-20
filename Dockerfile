FROM ubuntu:14.04
MAINTAINER marji@morpht.com

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y graphite-web graphite-carbon openssh-server supervisor

RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor

ADD conf/etc/graphite/local_settings.py /etc/graphite/local_settings.py
RUN /usr/bin/graphite-manage syncdb --noinput
RUN /bin/echo "CARBON_CACHE_ENABLED=true" > /etc/default/graphite-carbon


ADD conf/etc/carbon/carbon.conf /etc/carbon/carbon.conf
ADD conf/etc/carbon/storage-aggregation.conf /etc/carbon/storage-aggregation.conf
ADD conf/etc/carbon/storage-schemas.conf /etc/carbon/storage-schemas.conf

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 libapache2-mod-wsgi
RUN a2dissite 000-default

# Added "Alias /grafana /var/www/grafana" to /usr/share/graphite-web/apache2-graphite.conf
ADD conf/etc/apache2/sites-available/apache2-graphite.conf /etc/apache2/sites-available/apache2-graphite.conf

ADD http://grafanarel.s3.amazonaws.com/grafana-1.6.1.tar.gz /tmp/
RUN tar xzf /tmp/grafana-1.6.1.tar.gz -C /var/www/
RUN ln -s /var/www/grafana-1.6.1 /var/www/grafana
ADD conf/var/www/grafana/config.js /var/www/grafana/config.js

RUN a2ensite apache2-graphite

RUN chown _graphite:_graphite /var/lib/graphite
RUN chown _graphite:_graphite /var/lib/graphite/graphite.db

RUN echo 'root:secret' | chpasswd
RUN mkdir /root/.ssh && chmod 700 /root/.ssh

ADD id_rsa.pub /root/.ssh/authorized_keys

ADD supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# collectd:
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y collectd
ADD conf/etc/collectd/collectd.conf /etc/collectd/collectd.conf

EXPOSE 22
CMD ["/usr/bin/supervisord"]
