
. .setup_ubuntu_update.sh

# install docker
curl -sSL https://get.docker.com/ | sh

docker pull bizshuk/env_setup
docker tag bizshuk/env_setup  base


./setup_bash_env.sh
