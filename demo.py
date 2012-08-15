#! /usr/bin/python

# depond on python-sqlite2 & python-github, site as followed:
# "ftp://dtsh:111111@10.3.6.1/%2Fvar/ftp/dtsh/xiaoying/PyGithub"
# 'https://github.com/feiying/PyGithub.git'
from github import Github
import sqlite3
import sys
 
location = 'd_repos.sqlite'
table_name = 't_repolist'
 
def init_database():
    global conn
    global c
    conn = sqlite3.connect(location)
    c = conn.cursor()
    create_table()
 
def create_table():
    sql = 'CREATE TABLE IF NOT EXISTS ' + table_name + '(url text NOT NULL, date text, PRIMARY KEY(url))'
    c.execute(sql)
    conn.commit()
 
def insert_func(url, date):
    c.execute("INSERT INTO '%s' VALUES('%s', '%s')" % (table_name, url, date))
    conn.commit()
 
def query_func(url):
    c.execute("SELECT * FROM '%s' WHERE url= '%s'" % (table_name, url))
    conn.commit()
    #print "### query:", c.fetchone()
    return c;
 
def update_func(url, date):
    c.execute("UPDATE '%s' SET date='%s' where url= '%s'" % (table_name, date, url))
    conn.commit()
 
# github
name = 'gongzhq'
password = 'gzq2002'
g = Github(name, password)
authuser = g.get_user()
repos = g.get_user().get_repos()
for repo in repos:
    print "######### name: ", repo.name
    print "# fork num: ", repo.forks
    forks = repo.get_forks()
    for fork in forks:
        print "# clone url: ", fork.clone_url
        print "# updated_at: ", fork.updated_at
        print "# email: ", fork.owner.email

sys.exit()
 
 # sqlite2
init_database()
url='https://github.com/feiying/AppStream.git'
date='2012-05-28 05:48:38'
insert_func(url, date)
query_func(url)
c.close()
