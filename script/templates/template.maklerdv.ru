server {
    listen   80;
    
    root /usr/share/nginx/www;
    index index.html index.htm;
    
    server_name [% subdomain %].rplusmgmt.com;
    
    access_log /var/log/nginx/maklerdv.ru/clients/[% subdomain %]/access.log;
    error_log /var/log/nginx/maklerdv.ru/clients/[% subdomain %]/error.log;
    
    client_max_body_size 10m;
    
    location / {
            proxy_pass http://127.0.0.1:[% toad_port %];
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header X-Forwarded-HTTPS 0;
            include proxy_params;
    }
}