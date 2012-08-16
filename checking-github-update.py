#! /usr/bin/python

# depond on python-sqlite2 & python-github, site as followed:
# "ftp://dtsh:111111@10.3.6.1/%2Fvar/ftp/dtsh/xiaoying/PyGithub"
# 'https://github.com/feiying/PyGithub.git'
from github import Github
import sqlite3 as lite
import sys
 
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
        print "### '%s' has recorded in database." % url
        return True
    else:
        print "### '%s' hasn't recorded in database." % url
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
    	  print "### cmp : ", cmp_v
    	  if cmp_v > 0:
    	      return True
    	  else:
    	  	   return False
    return False
    
# init database
location = 'd_repos.sqlite'
table_name = 't_repolist'
init_database()
 
# login github
name = 'feiying'
password = 'feiying586878'
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
            	update_func(fork.ssh_url, fork.updated_at)
            	print "###### fetch code from site: '%s'" % fork.ssh_url
            else:
            	print "### update time is not changed."
        else:          
            insert_func(fork.ssh_url, fork.updated_at)
            print "###### fetch code from site: '%s'" % fork.ssh_url

c.close()
