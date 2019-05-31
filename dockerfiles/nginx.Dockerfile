FROM nginx:latest

ADD ./nginx.conf /etc/nginx/nginx.conf
ADD ./ssl/ /etc/nginx/ssl/

RUN chown -R root:root /etc/nginx/ssl
RUN chmod -R go-rwx /etc/nginx/ssl
