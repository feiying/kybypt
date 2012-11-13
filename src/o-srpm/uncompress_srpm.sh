#! /bin/bash

# global arguments
#RPMBUILD_TOP_DIR=${HOME}/rpmbuild
RPMBUILD_TOP_DIR=`rpm --eval %{_topdir}`
#RPMBUILD_BUILD_DIR=${RPMBUILD_TOP_DIR}/BUILD/
RPMBUILD_BUILD_DIR=`rpm --eval %{_builddir}`
#RPMBUILD_SOURCES_DIR=${RPMBUILD_TOP_DIR}/SOURCES/
RPMBUILD_SOURCES_DIR=`rpm --eval %{_sourcedir}`
#RPMBUILD_SPECS_DIR=${RPMBUILD_TOP_DIR}/SPECS/
RPMBUILD_SPECS_DIR=`rpm --eval %{_specdir}`
BUILD_TAR_FILE="rpmbuild-build.tar.gz"
SOURCE_TAR_NAME="rpmbuild-sources"
SOURCE_TAR_FILE=${SOURCE_TAR_NAME}".tar.gz"

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
echo "### INFO: rpmbuild - "${RPMBUILD_TOP_DIR}
if [ -d ${RPMBUILD_TOP_DIR} ]
then
    rm ${RPMBUILD_TOP_DIR} -rf
    echo "### INFO: clear build directory tree."
fi
echo "### INFO: init build directory tree."
rpmdev-setuptree

echo "### INFO: compress srpm"
rpm -Uvh $SRPM
echo "### INFO: create ${SOURCE_TAR_NAME}"
if [ -d ${PWD}/${SOURCE_TAR_NAME} ]
then
   rm ${PWD}/${SOURCE_TAR_NAME} -rf
fi
mkdir ${SOURCE_TAR_NAME} 
cp ${RPMBUILD_SOURCES_DIR}/* ${SOURCE_TAR_NAME} 
tar zcvf ${SOURCE_TAR_FILE} ${SOURCE_TAR_NAME}
mv ${SOURCE_TAR_FILE} ${RPMBUILD_SOURCES_DIR}

SPECS_NAME=`rpm -qp --qf "%{NAME}.spec" $SRPM`
SPECS=${RPMBUILD_SPECS_DIR}/${SPECS_NAME}
echo "### INFO spec- ${SPECS}"
if [ -e ${SPECS} ]
then
    rpmbuild -bp ${SPECS} --nodeps >/dev/null 2>&1
else
    echo "### ERROR: ${SPECS} is not exist."
fi

if [ -d ${PWD}/src ]
then
   echo "### INFO: src is exist now, please clean it"
   rm ${PWD}/src -rf
fi

#SUBDIR_N=`ls ${RPMBUILD_BUILD_DIR} | wc -l`
#echo "### INFO: SUBDIR_N: "${SUBDIR_N}
#if [ ${SUBDIR_N} -eq 0 ]
#then
    #echo "### INFO: The BUILD dir is null manually."
    #mkdir src
#elif [ ${SUBDIR_N} -eq 1 ]
#then
    SUBDIR_NAME=`ls ${RPMBUILD_BUILD_DIR}`
    #mv ${RPMBUILD_BUILD_DIR}/${SUBDIR_NAME} src
#else 
    #mkdir src
    #cp ${RPMBUILD_BUILD_DIR}/* src -rf
#fi

pushd ${RPMBUILD_BUILD_DIR}
tar zcvf ${BUILD_TAR_FILE} * >/dev/null
if [ $? -ne 0 ] 
then
   echo "### ERROR: archive the source dirs to ${BUILD_TAR_FILE}"
   exit 1
fi
mv ${BUILD_TAR_FILE} ${RPMBUILD_SOURCES_DIR}
popd

### modify spec
sed -n -e '{
   /^[:blank:]*Release/a  Source1000: rpmbuild-build.tar.gz
   /^[:blank:]*Release/a  Source1001: rpmbuild-sources.tar.gz
}' \
\
  -e '1,/^[:blank:]*%prep/{
    /^[:blank:]*%prep/a \%setup -q -b 1000
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
TMP_SRPM='/tmp/abc/'
if [ ! -e ${TMP_SRPM} ]
then
    mkdir ${TMP_SRPM}
fi
cp ${SRPM_FILE} ${TMP_SRPM} 

# clean building directory
echo "### INFO: rpmbuild - "${RPMBUILD_TOP_DIR}
if [ -d ${RPMBUILD_TOP_DIR} ]
then
    rm ${RPMBUILD_TOP_DIR} -rf
    echo "### INFO: clear build directory tree."
fi
rpmdev-setuptree

SRPM_NAME=`basename ${SRPM_FILE}`
rpm -Uvh ${TMP_SRPM}${SRPM_NAME} > /dev/null
rpmbuild -ba ${SPECS}
