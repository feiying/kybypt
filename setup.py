#!/user/bin/env python

from distutils.core import setup

setup(name='kybypt',
		version='1.0',
		author='xiaoying.hu',
		author_email='xiaoying.hu@cs2c.com.cn',
		url='https://github.com/feiying/kybypt',
		description='fetch update code from github, generate source rpm, and put srpm into koji to compile.',
		license='LGPLv2',
		py_Modules=['kybypt'],
		#packages=['kybypt'],
		#package_dir={'checking-github-update':'src/checking-github-update.py'},
		data_files=[('/usr/share/kybypt/doc', ['docs/Generating-SSH-Keys_github-help.pdf']),
		('/usr/bin/', ['src/checking-github-update.py']),
		('/usr/bin/', ['src/init-github-repo.py']),
		('/usr/bin/', ['src/uncompress-srpm.sh'])],
		#glob.glob(os.path.join('*.py')),
        #os.path.listdir(os.path.join('*.py'))
		)
