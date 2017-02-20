FROM nginx:stable

COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx.crt /etc/nginx/ssl/nginx.crt
COPY nginx.key /etc/nginx/ssl/nginx.key

EXPOSE 443
CMD ["nginx-debug", "-g", "daemon off;"]
