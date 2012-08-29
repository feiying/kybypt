#! /bin/bash

# global arguments
RPMBUILD_TOP_DIR=${HOME}/rpmbuild
RPMBUILD_BUILD_DIR=${RPMBUILD_TOP_DIR}/BUILD/
RPMBUILD_SOURCES_DIR=${RPMBUILD_TOP_DIR}/SOURCES/
RPMBUILD_SPECS_DIR=${RPMBUILD_TOP_DIR}/SPECS/
TAR_FILE="src.tar.gz"

# checking
if [ $# -ne 1 ]
then
    echo Usage: $0 srpm_path
    exit 1
fi

### compress source rpm
SRPM=$1
if ! echo "$1" | grep "\.src\.rpm$" > /dev/null
then
    echo "### ERROR: Please input the correct source rpm path."
    exit 1
fi
echo "### INFO: srpm - "${SRPM}

# clean building directory
echo "### INFO: rpmbuild - "${RPMBUILD_TOPDIR}
if [ -d ${RPMBUILD_TOP_DIR} ]
then
    rm ${RPMBUILD_TOP_DIR} -rf
    echo "### INFO: clear build directory tree."
fi
echo "### INFO: init build directory tree."
rpmdev-setuptree

echo "### INFO: compress srpm"
rpm -Uvh $SRPM
SPECS_NAME=`rpm -qp --qf "%{NAME}.spec" $SRPM`
SPECS=${RPMBUILD_SPECS_DIR}${SPECS_NAME}
echo "### INFO spec- ${SPECS}"
if [ -e ${SPECS} ]
then
    rpmbuild -bp ${SPECS} --nodeps >/dev/null 2>&1
else
    echo "### ERROR: ${SPECS} is not exist."
fi

SUBDIR_N=`ls ${RPMBUILD_BUILD_DIR} | wc -l`
if [ ${SUBDIR_N} -ne 1 ]
then
   echo "### ERROR: you should operate ${SRPM} manually."
   exit 1
fi
SUBDIR_NAME=`ls ${RPMBUILD_BUILD_DIR}`
if [ -d ${PWD}/src ]
then
   echo "### INFO: src is exist now, please clean it"
   rm ${PWD}/src -rf
fi
mv ${RPMBUILD_BUILD_DIR}${SUBDIR_NAME} src

tar zcvf ${TAR_FILE} src >/dev/null
if [ $? -ne 0 ] 
then
   echo "### ERROR: archive the source dirs to src.tar.gz"
   exit 1
fi

if [ -d ${PWD}/src ]
then
   rm ${PWD}/src -rf
fi

mv ${TAR_FILE} ${RPMBUILD_SOURCES_DIR}

### modify spec
sed -n -e '{
   s/^[:blank:]*Source/#Source/
   s/^[:blank:]*Patch/#Patch/
   /^[:blank:]*Release/a  Source: src.tar.gz
}' \
 \
  -e '1,/^[:blank:]*%prep/{
    /^[:blank:]*%prep/a \%setup -q -n src \n
    p
}' \
\
 -e '/^[:blank:]*%build/,/^[:blank:]*%install/{
    p
}' \
\
 -e '/^[:blank:]*%install/,${
    /[:blank:]*%install/d
    p
}' \
\
${SPECS}  > ${SPECS}.1

mv ${SPECS} ${SPECS}.orig
mv ${SPECS}.1 ${SPECS} -f

# generate srpm
SRPM_FILE=`rpmbuild -bs ${SPECS} | awk '{print $2}'`
echo "### INFO: compress srpm: ${SRPM_FILE}"
cp ${SRPM_FILE} . -f

rpm -Uvh ${SRPM_FILE} > /dev/null

rpmbuild -ba ${SPECS}
