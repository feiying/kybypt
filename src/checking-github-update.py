#! /usr/bin/python

# depond on python-sqlite2 & python-github, site as followed:
# "ftp://dtsh:111111@10.3.6.1/%2Fvar/ftp/dtsh/xiaoying/PyGithub"
# 'https://github.com/feiying/PyGithub.git'
from github import Github
import sqlite3 as lite
import os 
import sys
import shutil
import tarfile
 
def init_database():
    global conn
    global c
    conn = lite.connect(location)
    c = conn.cursor()
    create_table()
 
def create_table():
    sql = 'CREATE TABLE IF NOT EXISTS ' + table_name + '(url text NOT NULL, date text, PRIMARY KEY(url))'
    c.execute(sql)
    conn.commit()
 
def insert_func(url, date):
    print "### insert into database."
    c.execute("INSERT INTO '%s' VALUES('%s', '%s')" % (table_name, url, date))
    conn.commit()
 
def update_func(url, date):
    print "### update date in database."
    c.execute("UPDATE '%s' SET date='%s' where url= '%s'" % (table_name, date, url))
    conn.commit() 

def test_rec_exist(url):
    ''' test the record is exist in table '''
    c.execute("SELECT * FROM '%s' WHERE url= '%s'" % (table_name, url))
    conn.commit()
    res = c.fetchall()
    if len(res) > 0:
        print "### '%s' is exist in DB." % url
        return True
    else:
        print "### '%s' isn't exist in DB." % url
        return False
    
def update_time_is_changed(url, cur_updated):
    ''' compare currently time with last updated.'''
    c.execute("SELECT * FROM '%s' WHERE url = '%s'" % (table_name, url))
    conn.commit()
    val = c.fetchone() # NOTE: c.fetchone() doesn't assign multi time.
    if val == None:
        print "### last_updated is NULL"
        return False
    else:
    	  last_updated = val[1]
    	  print "### last_updated: ",last_updated
    	  print "### cur_updated: ",cur_updated.__str__()
    	  cmp_v = cmp(cur_updated.__str__(), last_updated)
    	  #print "### cmp : ", cmp_v
    	  if cmp_v > 0:
    	      return True
    	  else:
    	  	   return False
    return False
    
def copy_tar_to_rpmbuild_dir(s_dir):
    #print "### copy_tar_to_rpmbuild_dirs ..."
    arc_name= os.path.basename(s_dir)
    tar_name = "%s.tar.gz" % arc_name
    tar = tarfile.open(tar_name, "w:gz")
    tar.add(s_dir, arcname=arc_name)
    tar.close()
    rb_src_dir = os.path.join(os.getenv('HOME'), "rpmbuild/SOURCES/", tar_name)
    s_tarfile = os.path.join(os.path.dirname(s_dir), tar_name)
    print "### src: %s; dest: %s" % (s_tarfile, rb_src_dir)
    shutil.copyfile(s_tarfile, rb_src_dir)
    os.remove(s_tarfile)


def fetch_code_and_compress_srpm (url):
    name = os.path.basename(url).rstrip('.git')
    local_dir = os.path.join(os.getcwd(), name)
    if os.path.exists(local_dir):
        #print "### clear cache dir."
        shutil.rmtree(local_dir)

    cmd_pull = "git clone '%s'" % url
    os.system(cmd_pull)

    if os.path.exists(local_dir):
        os.chdir(local_dir)
        filelist = os.listdir(local_dir)
        for l_file in filelist:
            sub_file = os.path.join(local_dir, l_file)
            if os.path.isdir(sub_file):
                # compress srpm
                copy_tar_to_rpmbuild_dir(sub_file)
            else:
                spec_path = os.path.join(os.getenv('HOME'), "rpmbuild/SPECS/", os.path.basename(sub_file))
                print "### copy spec src: %s; dest: %s" %(sub_file, spec_path)
                shutil.copyfile(sub_file, spec_path)

    #  generate srpm via rpmbuild
    os.system('rpmbuild -bs %s' % spec_path)

# init database
location = 'd_repos.sqlite'
table_name = 't_repolist'
init_database()
 
# login github
name = 'cs2cone'
password = 'cs2c111111'
g = Github(name, password)
repos = g.get_user().get_repos()
for repo in repos:
    #print "######### name: ", repo.name
    #print "# fork num: ", repo.forks
    forks = repo.get_forks()
    for fork in forks:
        #print "# ssh url: ", fork.ssh_url
        #print "# updated_at: ", fork.updated_at
        #print "# email: ", fork.owner.email
        if test_rec_exist(fork.ssh_url):
            # compare the date
            if update_time_is_changed(fork.ssh_url, fork.updated_at):
            	print "######### The user catched new-commit, site: '%s'" % fork.ssh_url
                fetch_code_and_compress_srpm(fork.ssh_url)
            	update_func(fork.ssh_url, fork.updated_at)
            else:
            	print "### update time is not changed."
        else:          
            print "######### The user forked repo, site: '%s'" % fork.ssh_url
            fetch_code_and_compress_srpm(fork.ssh_url)
            insert_func(fork.ssh_url, fork.updated_at)

c.close()
