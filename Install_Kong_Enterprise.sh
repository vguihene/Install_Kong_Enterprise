#Check if the license is present
if [ "$#" -ne 1 ]; then
  echo "You must enter the license after ./Install_Kong_Enterprise.sh\n\tUSAGE:\n\t\t./Install_Kong_Enterprise.sh 'your_license_Kong_Enterprise'\n"
  exit 84
fi

#Start Docker
cd /Applications
open Docker.app
echo "<--- Starting Docker --->"
sleep 25

#Step 1. Pull the Kong Gateway Docker image
#Pull the following Docker image.

docker pull kong/kong-gateway:2.7.0.0-alpine

sleep 2

#Some older Kong Gateway images are not publicly accessible. If you need a specific patch version and can’t find it on Kong’s public Docker Hub page, contact Kong Support.
#You should now have your Kong Gateway image locally.
#Tag the image.

docker tag kong/kong-gateway:2.7.0.0-alpine kong-ee

sleep 2

#Step 2. Create a Docker network
#Create a custom network to allow the containers to discover and communicate with each other.

docker network create kong-ee-net

sleep 2

#Step 3. Start a database
#Start a PostgreSQL container:

docker run -d --name kong-ee-database \
  --network=kong-ee-net \
  -p 5432:5432 \
  -e "POSTGRES_USER=kong" \
  -e "POSTGRES_DB=kong" \
  -e "POSTGRES_PASSWORD=kong" \
  postgres:9.6

#Wait 5 secondes
sleep 5

#Step 4. Prepare the Kong database

docker run --rm --network=kong-ee-net \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-ee-database" \
  -e "KONG_PG_PASSWORD=kong" \
  -e "KONG_PASSWORD=kong" \
  kong-ee kong migrations bootstrap

#Wait 5 secondes
sleep 5

#Step 5. Start the gateway with Kong Manager

docker run -d --name kong-ee --network=kong-ee-net \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=kong-ee-database" \
  -e "KONG_PG_PASSWORD=kong" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001" \
  -e "KONG_ADMIN_GUI_URL=http://localhost:8002" \
    -p 8000:8000 \
    -p 8443:8443 \
    -p 8001:8001 \
    -p 8444:8444 \
    -p 8002:8002 \
    -p 8445:8445 \
    -p 8003:8003 \
    -p 8004:8004 \
    kong-ee

#Wait 5 secondes
sleep 5

#Step 6. Verify your installation
#Access the /services endpoint using the Admin API:

curl -i -X GET --url http://localhost:8001/services

#You should receive a 200 status code.

#Wait 5 secondes
sleep 5

#Deploy the license

curl -i -X POST http://localhost:8001/licenses \
  -d payload="$1"

#Wait 5 secondes
sleep 5

#In your container, set the Portal URL and set KONG_PORTAL to on:

 echo "KONG_PORTAL_GUI_HOST=localhost:8003 KONG_PORTAL=on kong reload exit" \
   | docker exec -i kong-ee /bin/sh

#Wait 5 secondes
sleep 5

#Execute the following command.

curl -X PATCH --url http://localhost:8001/workspaces/default \
     --data "config.portal=true"

#Wait 5 secondes
sleep 5

#Verify that Kong Manager is running by accessing it using the URL specified in KONG_ADMIN_GUI_URL in Step 5:

open http://localhost:8002

echo "\n<----- Kongratulation, you finished the Installation of Kong Enterprise ! ----->"
