#! /bin/bash

# global arguments
GLOBAL_RPMBUILD_TOP_DIR=`rpm --eval %{_topdir}`
RPMBUILD_BUILD_DIR=`rpm --eval %{_builddir}`
RPMBUILD_SOURCES_DIR=`rpm --eval %{_sourcedir}`
RPMBUILD_SPECS_DIR=`rpm --eval %{_specdir}`
SOURCE_TAR_NAME="rpmbuild-sources"
SOURCE_TAR_FILE=${SOURCE_TAR_NAME}".tar.gz"
BUILD_TAR_FILE="rpmbuild-build.tar.gz"
GLOBAL_SRPM_FILE=""
GLOBAL_SUBDIR_N=0
GLOBAL_SPECS=""

function clean_rpmbuild_dir()
{
	# clean building directory
	if [ -d ${GLOBAL_RPMBUILD_TOP_DIR} ]
	then
    	rm ${GLOBAL_RPMBUILD_TOP_DIR} -rf
	fi
    rpmdev-setuptree
}

function clean_temp_dirs_and_files()
{
	if [ -d ${PWD}/src ]
	then
		rm ${PWD}/src -rf
	fi

	if [ -d ${PWD}/${SOURCE_TAR_NAME} ]
	then
   		rm ${PWD}/${SOURCE_TAR_NAME} -rf
	fi
}

function install_orig_srpm()
{
	echo "### INFO: compress srpm"
	rpm -Uvh $GLOBAL_SRPM

	SPECS_NAME=`rpm -qp --qf "%{NAME}.spec" $GLOBAL_SRPM`
	GLOBAL_SPECS=${RPMBUILD_SPECS_DIR}/${SPECS_NAME}
	if [ -e ${GLOBAL_SPECS} ]
	then
    	rpmbuild -bp ${GLOBAL_SPECS} --nodeps >/dev/null 2>&1
	else
    	echo "### ERROR: ${GLOBAL_SPECS} is not exist."
        exit 1
	fi
}

function download_and_install_orig_srpm()
{
	install_orig_srpm
}

function constructe_rpmbuild_sources()
{
	mkdir ${SOURCE_TAR_NAME} 
	cp ${RPMBUILD_SOURCES_DIR}/* ${SOURCE_TAR_NAME} 
	tar zcvf ${SOURCE_TAR_FILE} ${SOURCE_TAR_NAME}
	mv ${SOURCE_TAR_FILE} ${RPMBUILD_SOURCES_DIR}
}

function constructe_rpmbuild_build()
{
    GLOBAL_SUBDIR_N=`ls ${RPMBUILD_BUILD_DIR} | wc -l`
    pushd ${RPMBUILD_BUILD_DIR}
    if [ $GLOBAL_SUBDIR_N -eq 0 ]
    then
        touch README
    fi
    tar zcvf ${BUILD_TAR_FILE} * >/dev/null
    if [ $? -ne 0 ] 
    then
       echo "### ERROR: archive the source dirs to ${BUILD_TAR_FILE}"
       exit 1
    fi
    mv ${BUILD_TAR_FILE} ${RPMBUILD_SOURCES_DIR}
    popd
}

function modify_rpmbuild_spec_nodir()
{
    ### modify spec
    sed -n -e '{
       1 i  Source10001: rpmbuild-sources.tar.gz
       p
    }' \
    \
    ${GLOBAL_SPECS}  > ${GLOBAL_SPECS}.1
    
    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS}

}

function modify_rpmbuild_spec_dirs_build()
{
    ### modify spec
	sed -n -e '{
       1 i  Source10000: rpmbuild-build.tar.gz
       1 i  Source10001: rpmbuild-sources.tar.gz
    }' \
    \
    -e '1, /^[:blank:]*%prep/{
       /^[:blank:]*%prep\>/a \%setup -q -b 10000 \n
        p
    }' \
    \
     -e '/^[:blank:]*%build\>/,${
        p
    }' \
    \
    ${GLOBAL_SPECS}  > ${GLOBAL_SPECS}.1
    
    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS} 
}

function modify_rpmbuild_spec_dirs_install()
{
    ### modify spec
	sed -n -e '{
       1 i  Source10000: rpmbuild-build.tar.gz
       1 i  Source10001: rpmbuild-sources.tar.gz
    }' \
    \
    -e '1, /^[:blank:]*%prep/{
       /^[:blank:]*%prep\>/a \%setup -q -b 10000 \n
        p
    }' \
    \
     -e '/^[:blank:]*%install\>/,${
        p
    }' \
    \
    ${GLOBAL_SPECS}  > ${GLOBAL_SPECS}.1
    
    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS} 
}

function modify_rpmbuild_spec_dirs_clean()
{
    ### modify spec
    sed -n -e '{
       1 i  Source10000: rpmbuild-build.tar.gz
       1 i  Source10001: rpmbuild-sources.tar.gz
    }' \
    \
    -e '1, /^[:blank:]*%prep/{
       /^[:blank:]*%prep\>/a \%setup -q -b 10000 \n
        p
    }' \
    \
     -e '/^[:blank:]*%clean\>/,${
        p
    }' \
    \
    ${GLOBAL_SPECS}  > ${GLOBAL_SPECS}.1
    
    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS} 
}

function modify_rpmbuild_spec_dirs_n_build()
{
	sed -n -e "{
       1 i  Source10000: rpmbuild-build.tar.gz
       1 i  Source10001: rpmbuild-sources.tar.gz
       /^[:blank:]*%build\>/i rm ${HOME}/rpmbuild/BUILD/* -rf
       /^[:blank:]*%build\>/i tar xf %{SOURCE10000} -C ${HOME}/rpmbuild/BUILD/\n
       p
    }" \
    ${GLOBAL_SPECS} > ${GLOBAL_SPECS}.1

    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS} 
    #exit 1
}

function modify_rpmbuild_spec_dirs_n_install()
{
	sed -n -e "{
       1 i  Source10000: rpmbuild-build.tar.gz
       1 i  Source10001: rpmbuild-sources.tar.gz
       /^[:blank:]*%install\>/i rm ${HOME}/rpmbuild/BUILD/* -rf
       /^[:blank:]*%install\>/i tar xf %{SOURCE10000} -C ${HOME}/rpmbuild/BUILD/\n
       p
    }" \
    \
    ${GLOBAL_SPECS} > ${GLOBAL_SPECS}.1

    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS} 
}

function modify_rpmbuild_spec_dirs_n_clean()
{
	sed -n -e "{
       1 i  Source10000: rpmbuild-build.tar.gz
       1 i  Source10001: rpmbuild-sources.tar.gz
       /^[:blank:]*%clean\>/i rm ${HOME}/rpmbuild/BUILD/* -rf
       /^[:blank:]*%clean\>/i tar xf %{SOURCE10000} -C ${HOME}/rpmbuild/BUILD/\n
       p
    }" \
    \
    ${GLOBAL_SPECS} > ${GLOBAL_SPECS}.1

    mv ${GLOBAL_SPECS} ${GLOBAL_SPECS}.orig
    mv ${GLOBAL_SPECS}.1 ${GLOBAL_SPECS} 
}

function modify_rpmbuild_specs()
{
	BUILD_HAVE_SUB_DIR=`grep  "^[[:space:]]*%setup\>" ${GLOBAL_SPECS} | wc -l`
    if [ $BUILD_HAVE_SUB_DIR -eq 0 ]
	then
        # no %prep section.
		modify_rpmbuild_spec_nodir
    else
		SETUP_NC=`grep "^[[:space:]]*%setup" ${GLOBAL_SPECS} | awk '{for(i=1;i<=NF;i++){if($i ~ /-[qc]*n/)print $(i+1)}}'`
		SETUP_T=`grep  "^[[:space:]]*%setup" ${GLOBAL_SPECS} | grep " -[qc]*T"`
		if [ "${SETUP_NC}""${SETUP_T}" ]
		then
            if grep "^[[:space:]]*%build\>" ${GLOBAL_SPECS}
            then
                # %build section exist
                echo "### INFO:1 %build seciton exist" >> re.log
       			modify_rpmbuild_spec_dirs_n_build
			elif grep "^[[:space:]]*%install\>" ${GLOBAL_SPECS}
            then
                # %install section exist
                echo "### INFO:1 %install seciton exist" >> re.log
       			modify_rpmbuild_spec_dirs_n_install
            elif grep "^[[:space:]]*%clean\>" ${GLOBAL_SPECS}
            then
                # %clean section exist
                echo "### INFO:1 %clean seciton exist" >> re.log
       			modify_rpmbuild_spec_dirs_n_clean
            else
                #echo "### ERROR: modify spec error1" >> re.log
			    exit 1 
            fi
        else
            if grep "^[[:space:]]*%build\>" ${GLOBAL_SPECS}
            then
                # %build section exist
                echo "### INFO:2 %build seciton exist" >> re.log
				modify_rpmbuild_spec_dirs_build
            elif grep "^[[:space:]]*%install\>" ${GLOBAL_SPECS}
            then
                # %install section exist
                echo "### INFO:2 %install seciton exist" >> re.log
				modify_rpmbuild_spec_dirs_install
            elif grep "^[[:space:]]*%clean\>" ${GLOBAL_SPECS}
            then
                # %clean section exist
                echo "### INFO:2 %clean seciton exist" >> re.log
				modify_rpmbuild_spec_dirs_clean
            else
                echo "### ERROR: modify  spec error2 " >> re.log
			    exit 1 
            fi
		fi
    fi
}

function generate_and_building_customized_srpm()
{
    # generate srpm
    GLOBAL_SRPM_FILE=`rpmbuild -bs ${GLOBAL_SPECS} | awk '{print $2}'`
    TMP_SRPM='/tmp/abc/'
    if [ ! -e ${TMP_SRPM} ]
    then
        mkdir ${TMP_SRPM}
    fi
    cp ${GLOBAL_SRPM_FILE} ${TMP_SRPM} 

    # refresh rpmbuild dir
    clean_rpmbuild_dir

    # install dependencies and build srpm
	SRPM_NAME=`basename ${GLOBAL_SRPM_FILE}`
	rpm -Uvh ${TMP_SRPM}${SRPM_NAME} > /dev/null
    sudo yum-builddep -y ${SRPM_NAME}
	rpmbuild -ba ${GLOBAL_SPECS}
}

### compress source rpm
function checking_input_paraments()
{
	if ! echo "$1" | grep "\.src\.rpm$" > /dev/null
	then
    	echo "### ERROR: Please input the correct source rpm path."
    	exit 1
	fi
}

function usage()
{
	echo Usage: $0 srpm_path
}
###### main ######
echo "### INFO: checking input paraments."
if [ $# -ne 1 ]
then
	usage
	exit 1
fi


GLOBAL_SRPM=$1
checking_input_paraments ${GLOBAL_SRPM}
echo "### INFO: srpm - "${GLOBAL_SRPM}

echo "### INFO: refresh build directory and temp directory."
clean_rpmbuild_dir
clean_temp_dirs_and_files

echo "### INFO: init build directory tree."
download_and_install_orig_srpm

echo "### INFO: constructe archive of rpmbuild SOURCES"
constructe_rpmbuild_sources

echo "### INFO: constructe archive of rpmbuild BUILD"
constructe_rpmbuild_build

echo "### INFO: modify spec SPEC"
modify_rpmbuild_specs

echo "### INFO: generate building customized srpm"
generate_and_building_customized_srpm
