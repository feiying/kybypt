import os
import shutil
from github import Github

name = 'gongzhq'
password = 'gzq2002'
g = Github(name, password)


# clear sensitive dir
pkg_name='acl'
src_dir='/tmp/acl'
dest_dir=os.path.join(os.getcwd(), pkg_name)
if os.path.exists(dest_dir):
    shutil.rmtree(dest_dir)

repo = g.get_user().create_repo(pkg_name)
cmd_clone = "git clone %s %s" % (repo.clone_url, pkg_name)
os.system(cmd_clone)

if os.path.exists(dest_dir):
    src_dir=os.path.join(src_dir, "/*")
    shutil.copytree(src_dir, dest_dir)

# add files 
os.chdir(dest_dir)
cmd_add = "git add *"
os.system(cmd_add)

# git commit
os.chdir(dest_dir)
cmd_commit = "git commit -m 'initial repository'" 
os.system(cmd_add)

# git push 
os.chdir(dest_dir)
cmd_push= "git push"
os.system(cmd_add)
