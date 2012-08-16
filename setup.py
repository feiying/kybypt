#!/user/bin/env python

from distutils.core import setup

setup(name='kybypt',
		version='1.0',
		py_Modules=['kybypt'],
		#packages=['kybypt'],
		package_dir={'*.py':'*.py'},
		#glob.glob(os.path.join('*.py')),
        #os.path.listdir(os.path.join('*.py'))
		)
