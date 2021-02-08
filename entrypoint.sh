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
apt-get install -y git python-pip && \

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

cd $GITHUB_WORKSPACE

echo "Clean folder ..."
./node_modules/hexo/bin/hexo clean

echo "Generate file ..."
./node_modules/hexo/bin/hexo generate 


echo "Config git ..."

# setup key
mkdir -p /root/.ssh/
echo "${INPUT_DEPLOYKEY}" >/root/.ssh/id_rsa
chmod 600 /root/.ssh/id_rsa
ssh-keyscan -t rsa github.com >>/root/.ssh/known_hosts


git config --global user.name "githubDeployActionQWQ"
git config --global user.email "githubDeployActionQWQ@QAQ.com"


cd $PUBLISH_DIR
echo 'Deploying... (github)'


git init
# git config user.name "${GITHUB_ACTOR}"
# git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git remote add origin git@github.com:ShuYuMo2003/ShuYuMo2003.github.io.git
git checkout --orphan $BRANCH

git add --all

echo 'Start Commit'
git commit --allow-empty -m "Deploying to ${BRANCH}"

echo 'Start Push'
git push origin "${BRANCH}" --force
echo "Deployment succesfully!(github)"

echo "Deploying... (gitee)"
ssh-keyscan -t rsa gitee.com >> /root/.ssh/known_hosts
mkdir $GITHUB_WORKSPACE/sync_with_gitee
cd $GITHUB_WORKSPACE/sync_with_gitee
git clone git@gitee.com:ShuYuMo2003/ShuYuMo2003.git
mv ShuYuMo2003/.git .
rm -rf ShuYuMo2003
cp -r $GITHUB_WORKSPACE/$PUBLISH_DIR ShuYuMo2003
mv .git ShuYuMo2003/.git
cd ShuYuMo2003
echo "repo Init done.(gitee)"
echo "show files"
ls -a
git add *
git diff-index --quiet HEAD || git commit -m "update content by github action. QAQAQAQ~"
echo "show files"
ls -a
git push origin master -f

echo "Deployment succesfully!(gitee)"



echo "pushing url to baidu.(github)"

cd $GITHUB_WORKSPACE

echo "
import requests
import re
with open('public/sitemap.xml', 'r') as sitemap:
    pattern = re.compile(r'(?<=<loc>).+?(?=</loc>)')
    result = pattern.findall(sitemap.read())
    data = []
    for i in result:
        temp = ''
        if(i[0] != '/'): temp = '/'
        if(i == 'http://shuyumo2003.github.io/'):
            data.append('https://shuyumo2003.github.io/')
        else:
            data.append('https://shuyumo2003.github.io' + temp + i)
    req = requests.post('http://data.zz.baidu.com/urls?site=https://shuyumo2003.github.io&token=${BAIDU_PUSH}', chr(10).join(data))
    print(chr(10).join(data))
    print(req.text)
" > push_baidu_github.py

pip install requests

python push_baidu_github.py


echo "pushing url to baidu.(gitee)"

cd $GITHUB_WORKSPACE

echo "
import requests
import re
with open('public/sitemap.xml', 'r') as sitemap:
    pattern = re.compile(r'(?<=<loc>).+?(?=</loc>)')
    result = pattern.findall(sitemap.read())
    data = []
    for i in result:
        temp = ''
        if(i[0] != '/'): temp = '/'
        if(i == 'http://shuyumo2003.github.io/'):
            data.append('https://shuyumo2003.gitee.io/')
        else:
            data.append('https://shuyumo2003.gitee.io' + temp + i)
    req = requests.post('http://data.zz.baidu.com/urls?site=https://shuyumo2003.gitee.io&token=${BAIDU_PUSH}', chr(10).join(data))
    print(chr(10).join(data))
    print(req.text)
" > push_baidu_gitee.py

python push_baidu_gitee.py

echo 'Successfully!'