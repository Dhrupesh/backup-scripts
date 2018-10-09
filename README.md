# backup-scripts
backup scripts for odoo instance farm

# Which images to pull
docker pull postgres:9.1
docker pull postgres:9.3
docker pull postgres:9.5
docker pull postgres:9.6
docker pull registry:2
docker pull zerotier/zerotier-containerized
docker pull portainer/portainer

## to run zerotier in CoreOS:
docker run --device=/dev/net/tun --net=host --cap-add=NET_ADMIN --cap-add=SYS_ADMIN -d -v /var/lib/zerotier-one:/var/lib/zerotier-one --name zerotier-one zerotier/zerotier-containerized

## To join a zerotier network:
docker exec zerotier-one /zerotier-cli join "ID"

# To create keys for docker registry
cd /opt/
ls -la
cd registry/
ls -la
mkdir -p certs
sudo mkdir -p certs
sudo openssl req   -newkey rsa:4096 -nodes -sha256 -keyout certs/domain.key   -x509 -days 365 -out certs/domain.crt

# To create registry container
docker run -d   --restart=always   --name 
registry   -v /opt/registry/certs:/certs -v /opt/registry/config.yml:/etc/docker/registry/config.yml  -v /mnt/prod-NSM/registry:/var/lib/registry  -e REGISTRY_HTTP_ADDR=0.0.0.0:443   -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt   -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key   -p 443:443   registry:2

# Content of /etc/hosts:
172.128.1.195	bdu-prod \
172.128.1.159	bdu-test \
172.128.1.188	multi-tenant01 \
172.128.1.180	magnus-prod \
172.128.1.213	nsm-prod \
10.147.18.118	development \
10.131.0.27	nsm-prod-70 \
10.131.1.21	nsm-test

# To mount an nfs share when booting
# Not sure it works like this
Create user_data file in 
cd /media/configdrive/openstack/latest
echo "#cloud-config
coreos:
 units:
    - name: rpc-statd.service
      command: start
      enable: true
    - name: mnt-prod\x2dNSM.mount
      command: start
      content: |
        [Mount]
        What=172.128.0.36:/mnt/Array-1/Odoo-shares
        Where=/mnt/prod-NSM
        Type=nfs
    - name: docker.service
      command: start
      enable: true" >> user_data