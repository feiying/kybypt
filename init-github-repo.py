#!/usr/bin/python

import os
import shutil
from github import Github

name = 'feiying'
password = 'feiying586878'
g = Github(name, password)


# clear sensitive dir
pkg_name='acl'
src_dir=os.path.join('/tmp/', pkg_name)
dest_dir=os.path.join(os.getcwd(), pkg_name)
if os.path.exists(dest_dir):
    print "### the old directory \''%s'\' is exist now, then clear it" % dest_dir
    shutil.rmtree(dest_dir)

repo = g.get_user().create_repo(pkg_name)
print "### git clone init repo '%s'" % pkg_name 
cmd_clone = "git clone %s %s" % (repo.ssh_url, pkg_name)
os.system(cmd_clone)

if os.path.exists(dest_dir):
    print "### git clone repo %s completely." % pkg_name
    filelist = os.listdir(src_dir)
    for file in filelist:
        s_file = os.path.join(src_dir, file)
        d_file = os.path.join(dest_dir, file)
        if os.path.isdir(s_file):
            print "### source dir: '%s' # destination dir: '%s'" % (s_file, d_file)
            shutil.copytree(s_file, d_file)
        else:
            print "### source file: '%s' # destination file: '%s'" % (s_file, d_file)
            shutil.copyfile(s_file, d_file)
    

# add files 
os.chdir(dest_dir)
cmd_add = "git add *"
os.system(cmd_add)

# git commit
os.chdir(dest_dir)
cmd_commit = "git commit -m \'initial repository\'" 
os.system(cmd_commit)

# git push 
os.chdir(dest_dir)
cmd_push= "git push -u origin master"
os.system(cmd_push)
