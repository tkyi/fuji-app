#!/bin/bash

chmod -R 755 ~/app


INSTANCE_USER=ubuntu
HOME="/var/www/html"
NGINX_WORKERS=4
SERVER_NAME=fuji-app.local
NODE_ENV=production
NAME=fuji-app-production

echo "code_deploy: nginx"
sudo mkdir -p /var/log/nginx
sudo chown $INSTANCE_USER /var/log/nginx
sudo chmod -R 755 /var/log/nginx

echo "code_deploy: nginx as a service"
sudo update-rc.d nginx defaults


echo "code_deploy: updating nginx configuration"
cp -r $HOME/app/scripts/nginx $HOME/app/nginx

sed -i "s#{NGINX_USER}#$INSTANCE_USER#g" $HOME/app/nginx/nginx.conf
sed -i "s#{NGINX_WORKERS}#$NGINX_WORKERS#g" $HOME/app/nginx/nginx.conf
sed -i "s#{SERVER_NAME}#$SERVER_NAME#g" $HOME/app/nginx/site.conf
sed -i "s#{STATIC_ROOT}#$HOME/app/server/public#g" $HOME/app/nginx/site.conf

sudo ln -sfn $HOME/app/nginx/nginx.conf /etc/nginx/nginx.conf
sudo ln -sfn $HOME/app/nginx/site.conf /etc/nginx/sites-enabled/$NAME.conf
sudo rm /etc/nginx/sites-enabled/default

sudo service nginx restart || sudo service nginx start || (sudo cat /var/log/nginx/error.log && exit 1)

echo "code_deploy: installing appserver daemon..."
echo "#!/bin/bash" > $HOME/app/start
echo "NODE_ENV=$NODE_ENV node $HOME/app/server/index" >> $HOME/app/start
chmod +x $HOME/app/start
cp $HOME/app/scripts/init.d/appserver.conf $HOME/app/$NAME.conf
sed -i "s#{NAME}#$NAME#g" $HOME/app/$NAME.conf
sed -i "s#{DESCRIPTION}#Web application daemon service for $NAME#g" $HOME/app/$NAME.conf
sed -i "s#{USER}#$INSTANCE_USER#g" $HOME/app/$NAME.conf
sed -i "s#{COMMAND}#$HOME/app/start#g" $HOME/app/$NAME.conf
sudo mv $HOME/app/$NAME.conf /etc/init.d/$NAME
sudo chmod +x /etc/init.d/$NAME
sudo touch /var/log/$NAME.log
sudo chown $INSTANCE_USER /var/log/$NAME.log
sudo update-rc.d $NAME defaults

echo "code_deploy: install node modules"
cd $HOME/app/server
npm install
