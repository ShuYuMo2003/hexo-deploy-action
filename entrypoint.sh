#!/bin/sh -l

set -e

# check values
if [ -n "${PUBLISH_REPOSITORY}" ]; then
    PRO_REPOSITORY=${PUBLISH_REPOSITORY}
else
    PRO_REPOSITORY=${GITHUB_REPOSITORY}
fi

if [ -z "$PUBLISH_DIR" ]
then
  echo "You must provide the action with the folder path in the repository where your compiled page generate at, example public."
  exit 1
fi

if [ -z "$BRANCH" ]
then
  echo "You must provide the action with a branch name it should deploy to, for example master."
  exit 1
fi

# deploy to 
echo "Deploy to ${PRO_REPOSITORY}"

# Installs Git and jq.
apt-get update && \
apt-get install -y git && \

echo "installing pandoc" 

wget https://github.com/jgm/pandoc/releases/download/2.7/pandoc-2.7-1-amd64.deb
dpkg -i ./pandoc-2.7-1-amd64.deb

# Directs the action to the the Github workspace.
cd $GITHUB_WORKSPACE 

echo "npm install ... (hexo)" 
npm install
cd $GITHUB_WORKSPACE/themes/next
echo "npm install ... (next)" 
# pwd
npm install

echo $REPOSITORY_PATH

cd $GITHUB_WORKSPACE

echo "Clean folder ..."
./node_modules/hexo/bin/hexo clean

echo "Generate file ..."
./node_modules/hexo/bin/hexo generate 

cd $PUBLISH_DIR

echo "Config git ..."

# setup key
mkdir -p /root/.ssh/
echo "${INPUT_DEPLOYKEY}" >/root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts

git config --global user.name "githubDeployAction"
git config --global user.email "githubDeployAction@QAQ.com"


echo 'Deploying...'
./node_modules/hexo/bin/hexo d

echo "Deployment succesful!"