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


echo "replace gitalkID"

echo "
f = open('_config.yml', 'r').read()
f = f.replace(    r'{{GITALK_CLIENT_ID}}', '${GITALK_CLIENT_ID}')
f = f.replace(r'{{GITALK_CLIENT_SECRET}}', '${GITALK_CLIENT_SECRET}')
d = open('_config.yml', 'w')
d.write(f)
d.flush()
d.close()
" > temp.py

python temp.py



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

echo "pushing url to baidu.(github)"

cd $GITHUB_WORKSPACE

echo "
print('running in python srcipt')
import requests
import re
with open('public/sitemap.xml', 'r') as sitemap:
    pattern = re.compile(r'(?<=<loc>).+?(?=</loc>)')
    result = pattern.findall(sitemap.read())
    data = []
    print('read done')
    for i in result:
        temp = ''
        if(i[0] != '/'): temp = '/'
        if(i == 'http://shuyumo2003.github.io/'):
            data.append('https://shuyumo2003.github.io/')
        else:
            data.append('https://shuyumo2003.github.io' + temp + i)
    print('posting...')
    req = requests.post('http://data.zz.baidu.com/urls?site=https://shuyumo2003.github.io&token=${BAIDU_PUSH}', chr(10).join(data))
    print('done')
    print(chr(10).join(data))
    print(req.text)
" > push_baidu_github.py

pip install requests

python push_baidu_github.py


echo "pushing url to baidu.(gitee)"

cd $GITHUB_WORKSPACE

echo "
print('running in python srcipt')
import requests
import re
with open('public/sitemap.xml', 'r') as sitemap:
    pattern = re.compile(r'(?<=<loc>).+?(?=</loc>)')
    result = pattern.findall(sitemap.read())
    data = []
    print('read done')
    for i in result:
        temp = ''
        if(i[0] != '/'): temp = '/'
        if(i == 'http://shuyumo2003.github.io/'):
            data.append('https://shuyumo2003.gitee.io/')
        else:
            data.append('https://shuyumo2003.gitee.io' + temp + i)
    print('posting...')
    req = requests.post('http://data.zz.baidu.com/urls?site=https://shuyumo2003.gitee.io&token=${BAIDU_PUSH}', chr(10).join(data))
    print('done.')
    print(chr(10).join(data))
    print(req.text)
" > push_baidu_gitee.py

python push_baidu_gitee.py

echo 'Successfully!'