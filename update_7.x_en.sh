#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

if [ ! -d /www/server/panel/BTPanel ];then
	echo "============================================="
	echo "Error, 5.x Can't use this command to upgrade!"
	exit 0;
fi

Updating="/tmp/update_to7.pl"
if [ -f "$Updating" ];then
    echo "Error, $Updating file exists. Please delete this $Updating before executing the command."
    exit 0;
else
    touch $Updating
fi


# public_file=/www/server/panel/install/public.sh
# publicFileMd5=$(md5sum ${public_file} 2>/dev/null|awk '{print $1}')
# md5check="f3fb69f071f7fa800e5f2d5ec3e128c3"
# if [ "${publicFileMd5}" != "${md5check}"  ]; then
# 	wget -O Tpublic.sh https://node.aapanel.com/install/public.sh -T 20;
# 	publicFileMd5=$(md5sum Tpublic.sh 2>/dev/null|awk '{print $1}')
# 	if [ "${publicFileMd5}" == "${md5check}"  ]; then
# 		\cp -rpa Tpublic.sh $public_file
# 	fi
# 	rm -f Tpublic.sh
# fi

# . $public_file

if [ -f /etc/redhat-releas ]; then
    Centos8Check=$(cat /etc/redhat-release | grep ' 8.' | grep -iE 'centos|Red Hat')
    if [ "${Centos8Check}" ];then
        if [ ! -f "/usr/bin/python" ] && [ -f "/usr/bin/python3" ] && [ ! -d "/www/server/panel/pyenv" ]; then
            ln -sf /usr/bin/python3 /usr/bin/python
        fi
    fi
fi

# download_Url=$NODE_URL
# if [ "$download_Url" = "" ];then
# 	download_Url=https://node.aapanel.com
# fi

download_Url=https://node.aapanel.com

setup_path="/www"
python_bin=$setup_path/server/panel/pyenv/bin/python
cpu_cpunt=$(cat /proc/cpuinfo | grep ^processor | wc -l)
is64bit=$(getconf LONG_BIT)

GetSysInfo() {
    if [ -s "/etc/redhat-release" ]; then
        SYS_VERSION=$(cat /etc/redhat-release)
    elif [ -s "/etc/issue" ]; then
        SYS_VERSION=$(cat /etc/issue)
    fi
    SYS_INFO=$(uname -a)
    SYS_BIT=$(getconf LONG_BIT)
    MEM_TOTAL=$(free -m | grep Mem | awk '{print $2}')
    CPU_INFO=$(getconf _NPROCESSORS_ONLN)

    echo -e ${SYS_VERSION}
    echo -e Bit:${SYS_BIT} Mem:${MEM_TOTAL}M Core:${CPU_INFO}
    echo -e ${SYS_INFO}
    echo -e "Please screenshot the above error message and post to the forum forum.aapanel.com for help"
}

Red_Error(){
    echo '============== Update Failed! ==============='
    printf '\033[1;31;40m%b\033[0m\n' "$@";
    GetSysInfo

    if [ $Install_pyenv_fielded == "yes" ] && [ -d "$pyenv_path/pyenv_update-panel" ]; then
        if [ -d "$pyenv_path/pyenv" ]; then
            if [ -d "$pyenv_path/pyenv_update-fail" ]; then
                rm -rf $pyenv_path/pyenv_update-fail
            fi
            mv $pyenv_path/pyenv $pyenv_path/pyenv_update-fail
        fi
        echo "Restoring pyenv directory"
        mv $pyenv_path/pyenv_update-panel $pyenv_path/pyenv
    fi

    /etc/init.d/bt start
    rm -f $Updating
    echo '============== Update Failed! ==============='
	exit 1;
}

Get_Pack_Manager() {
    if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
        PM="yum"
    elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
        PM="apt-get"
    fi
}

Install_RPM_Pack() {
    if [ -f "/etc/redhat-release" ] && [ $(cat /etc/os-release|grep PLATFORM_ID|grep -oE "el8") ];then
        yum config-manager --set-enabled powertools
        yum config-manager --set-enabled PowerTools
    fi

    if [ -f "/etc/redhat-release" ] && [ $(cat /etc/os-release|grep PLATFORM_ID|grep -oE "el9") ];then
        dnf config-manager --set-enabled crb -y
    fi

    sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
    #yum remove -y python-requests python3-requests python-greenlet python3-greenlet
    yumPacks="libcurl-devel wget tar gcc make zip unzip openssl openssl-devel gcc libxml2 libxml2-devel libxslt* zlib zlib-devel libjpeg-devel libpng-devel libwebp libwebp-devel freetype freetype-devel lsof pcre pcre-devel vixie-cron crontabs icu libicu-devel c-ares libffi-devel bzip2-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel firewalld ipset libpq-devel"
    yum install -y ${yumPacks}

    for yumPack in ${yumPacks}; do
        rpmPack=$(rpm -q ${yumPack})
        packCheck=$(echo ${rpmPack} | grep not)
        if [ "${packCheck}" ]; then
            yum install ${yumPack} -y
        fi
    done
    if [ -f "/usr/bin/dnf" ]; then
        dnf install -y redhat-rpm-config
    fi

    ALI_OS=$(cat /etc/redhat-release | grep "Alibaba Cloud Linux release 3")
    if [ -z "${ALI_OS}" ]; then
        yum install epel-release -y
    fi
}

Install_Deb_Pack() {

    debPacks="wget curl libcurl4-openssl-dev gcc make zip unzip tar openssl libssl-dev gcc libxml2 libxml2-dev zlib1g zlib1g-dev libjpeg-dev libpng-dev lsof libpcre3 libpcre3-dev cron net-tools swig build-essential libffi-dev libbz2-dev libncurses-dev libsqlite3-dev libreadline-dev tk-dev libgdbm-dev libdb-dev libdb++-dev libpcap-dev xz-utils git ufw ipset sqlite3 uuid-dev libpq-dev liblzma-dev"

    #DEBIAN_FRONTEND=noninteractive apt-get install -y $debPacks --allow-downgrades --allow-remove-essential --allow-change-held-packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y $debPacks --force-yes

    for debPack in ${debPacks}; do
        packCheck=$(dpkg -l ${debPack})
        if [ "$?" -ne "0" ]; then
            DEBIAN_FRONTEND=noninteractive apt-get install -y $debPack --force-yes
        fi
    done

}

Get_Versions() {
    redhat_version_file="/etc/redhat-release"
    deb_version_file="/etc/issue"

    if [[ $(grep OpenCloudOS /etc/os-release) ]]; then
        os_type="OpenCloudOS-"
        os_version=$(cat /etc/os-release | grep OpenCloudOS | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        if [[ $os_version == "7" ]]; then
            os_type="el"
            os_version="7"
        fi 
        return
    fi

    if [[ $(grep "Linux Mint" $deb_version_file) ]]; then
        os_version=$(cat $deb_version_file | grep "Linux Mint" | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        if [ "${os_version}" = "" ]; then
            os_version=$(cat $deb_version_file | grep "Linux Mint" | grep -Eo '[0-9]+')
        fi
        # Linux-Mint 使用 ubuntu pyenv
        os_type='ubuntu'
        if [[ "$os_version" =~ "21" ]]; then
            os_version="22"
            echo "$os_version"
        fi
        if [[ "$os_version" =~ "20" ]]; then
            os_version="20"
            echo "$os_version"
        fi
        return
    fi

    if [[ $(grep openEuler /etc/os-release) ]]; then
        os_type="openEuler-"
        os_version=$(cat /etc/os-release | grep openEuler | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        return
    fi

    if [[ $(grep AlmaLinux /etc/os-release) ]]; then
        os_type="Alma-"
        os_version=$(cat /etc/os-release | grep AlmaLinux | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        return
    fi

    if [[ $(grep Rocky /etc/os-release) ]]; then
        os_type="Rocky-"
        os_version=$(cat /etc/os-release | grep Rocky | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        return
    fi

    if [[ $(grep Anolis /etc/os-release) ]] && [[ $(grep VERSION /etc/os-release|grep 8.8) ]];then
        if [ -f "/usr/bin/yum" ];then
            os_type="anolis"
            os_version="8"
            return
        fi
    fi        

    if [ -f $redhat_version_file ]; then
        os_type='el'
        if [[ $(grep 'Alibaba Cloud Linux (Aliyun Linux) release 2' $redhat_version_file) ]]; then
            os_version="7"
            return
        fi

        is_aliyunos=$(cat $redhat_version_file | grep Aliyun)
        if [ "$is_aliyunos" != "" ]; then
            return
        fi

        if [[ $(grep "Red Hat" $redhat_version_file) ]]; then
            os_type='el'
            os_version=$(cat $redhat_version_file | grep "Red Hat" | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]')
            return
        fi

        if [[ $(grep "Alibaba Cloud Linux release 3 " /etc/redhat-release) ]]; then
            os_type="ali-linux-"
            os_version="3"
            return
        fi

        if [[ $(grep "Alibaba Cloud" /etc/redhat-release) ]] && [[ $(grep al8 /etc/os-release) ]];then
            os_type="ali-linux-"
            os_version="al8"
            return
        fi

        if [[ $(grep TencentOS /etc/redhat-release) ]]; then
            os_type="TencentOS-"
            os_version=$(cat /etc/redhat-release | grep TencentOS | grep -Eo '([0-9]+\.)+[0-9]+')
            if [[ $os_version == "2.4" ]]; then
                os_type="el"
                os_version="7"
            elif [[ $os_version == "3.1" ]]; then
                os_version="3.1"
            fi
            return
        fi

        os_version=$(cat $redhat_version_file | grep CentOS | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]')
        if [ "${os_version}" = "5" ]; then
            os_version=""
        fi
        if [ -z "${os_version}" ]; then
            os_version=$(cat /etc/redhat-release | grep Stream | grep -oE "8|9")
        fi
    else
        os_type='ubuntu'
        os_version=$(cat $deb_version_file | grep Ubuntu | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '^[0-9]+')
        if [ "${os_version}" = "" ]; then
            os_type='debian'
            os_version=$(cat $deb_version_file | grep Debian | grep -Eo '([0-9]+\.)+[0-9]+' | grep -Eo '[0-9]+')
            if [ "${os_version}" = "" ]; then
                os_version=$(cat $deb_version_file | grep Debian | grep -Eo '[0-9]+')
            fi
            if [ "${os_version}" = "8" ]; then
                os_version=""
            fi
            if [ "${is64bit}" = '32' ]; then
                os_version=""
            fi
        else
            if [ "$os_version" = "14" ]; then
                os_version=""
            fi
            if [ "$os_version" = "12" ]; then
                os_version=""
            fi
            if [ "$os_version" = "19" ]; then
                os_version=""
            fi
            if [ "$os_version" = "21" ]; then
                os_version=""
            fi
            if [ "$os_version" = "20" ]; then
                os_version2004=$(cat /etc/issue | grep 20.04)
                if [ -z "${os_version2004}" ]; then
                    os_version=""
                fi
            fi
        fi
    fi
}

Install_Openssl111(){
    Get_Versions
    if [ -f "/www/server/panel/openssl_make.pl" ]; then
        openssl_make="yes"
        rm -f /www/server/panel/openssl_make.pl
    fi

    CPU_arch=$(uname -m)
    if [ "${CPU_arch}" == "aarch64" ];then
        CPU_arch="-aarch64"
    elif [ "${CPU_arch}" == "x86_64" ];then
        # x86_64 默认为空
        CPU_arch=""
    else
        openssl_make="yes"
    fi

    if [[ $os_type = "el" ]] && [[ $os_version == "7" ]] && [[ $openssl_make != "yes" ]]; then
        wget --no-check-certificate -O openssl111.tar.gz ${download_Url}/install/src/openssl111${CPU_arch}.tar.gz -t 5 -T 20
        tmp_size=$(du -b openssl111.tar.gz | awk '{print $1}')
        if [ $tmp_size -lt 5014046 ]; then
            rm -f openssl111.tar.gz
            Red_Error "ERROR: Download openssl111.tar.gz fielded."
        fi
        tar zxvf openssl111.tar.gz -C /usr/local/
        rm -f openssl111.tar.gz
        if [ ! -f "/usr/local/openssl111/bin/openssl" ];then
            Red_Error "/usr/local/openssl111/bin/openssl file does not exist!"
        fi
        export LD_LIBRARY_PATH=/usr/local/openssl111/lib:$LD_LIBRARY_PATH
        echo "/usr/local/openssl111/lib" > /etc/ld.so.conf.d/zopenssl111.conf
        ldconfig
    else
        if [ -f "/usr/bin/yum" ]; then
            yum install -y perl lksctp-tools-devel
        else
            apt install -y perl
        fi
        opensslVersion="1.1.1o"
        wget --no-check-certificate -O openssl-${opensslVersion}.tar.gz ${download_Url}/src/openssl-${opensslVersion}.tar.gz -t 5 -T 20
        tmp_size=$(du -b openssl-${opensslVersion}.tar.gz | awk '{print $1}')
        if [ $tmp_size -lt 9056386 ]; then
            rm -f openssl-${opensslVersion}.tar.gz
            Red_Error "ERROR: Download openssl-${opensslVersion}.tar.gz fielded."
        fi
        tar -zxvf openssl-${opensslVersion}.tar.gz
        if [ ! -d "openssl-${opensslVersion}" ];then
            Red_Error "Decompression failed openssl-${opensslVersion} Directory does not exist!"
        fi
        cd openssl-${opensslVersion}
        ./config --prefix=/usr/local/openssl111 --openssldir=/usr/local/openssl111 enable-md2 enable-rc5 sctp zlib-dynamic shared -fPIC
        make -j$cpu_cpunt
        make install
        if [ ! -f "/usr/local/openssl111/bin/openssl" ];then
            Red_Error "Compilation failed /usr/local/openssl111/bin/openssl file does not exist!"
        fi
        export LD_LIBRARY_PATH=/usr/local/openssl111/lib:$LD_LIBRARY_PATH
        echo "/usr/local/openssl111/lib" > /etc/ld.so.conf.d/zopenssl111.conf
        ldconfig
        cd ..
        rm -rf openssl-${opensslVersion} openssl-${opensslVersion}.tar.gz
    fi
    openssl111Check=$(/usr/local/openssl111/bin/openssl version|grep 1.1.1)
    if [ -z "${openssl111Check}" ];then
        Red_Error "openssl-1.1.1 install failed!"
    fi
}

Update_Py_Lib(){
# 需要使用 Werkzeug 2.2.3
    mypip="/www/server/panel/pyenv/bin/pip"
    Werkzeug_path="/www/server/panel/script/Werkzeug-2.2.3-py3-none-any.whl"

    Werkzeug_v=$($mypip list|grep Werkzeug | grep 2.2.3)
    if [ "$Werkzeug_v" = "" ];then
        echo "Update Werkzeug"
        $mypip uninstall Werkzeug -y 
        $mypip install $Werkzeug_path

        Werkzeug_v_2=$($mypip list|grep Werkzeug | grep 2.2.3)
        if [ "$Werkzeug_v_2" = "" ];then
            $mypip install Werkzeug==2.2.3
        fi
    fi
}

Install_Python_Lib() {

    # openssl 版本低于1.1.1 需要安装 如CentOS 7
    OPENSSL_VER=$(openssl version|grep -oE '1.0|1.1.0')
    if [ "${OPENSSL_VER}" ]; then
        
        if [ ! -f "/usr/local/openssl111/bin/openssl" ]; then
            Install_Openssl111
        else
            export LD_LIBRARY_PATH=/usr/local/openssl111/lib:$LD_LIBRARY_PATH
            openssl111Check=$(/usr/local/openssl111/bin/openssl version|grep 1.1.1)
            if [ -z "${openssl111Check}" ];then
                Install_Openssl111
            fi
            if [ ! -f "/etc/ld.so.conf.d/openssl111.conf" ] || [ ! -f "/etc/ld.so.conf.d/zopenssl111.conf" ]; then
                echo "/usr/local/openssl111/lib" > /etc/ld.so.conf.d/zopenssl111.conf
                ldconfig
            fi
        fi
        Use_Openssl111="yes"
    fi

    curl -Ss --connect-timeout 3 -m 60 $download_Url/install/pip_select.sh | bash
    pyenv_path="/www/server/panel"
    if [ -f $pyenv_path/pyenv/bin/python ]; then
        is_ssl=$($python_bin -c "import ssl" 2>&1 | grep cannot)
        $pyenv_path/pyenv/bin/python3.12 -V
        if [ $? -eq 0 ] && [ -z "${is_ssl}" ]; then
            chmod -R 700 $pyenv_path/pyenv/bin
            is_package=$($python_bin -m psutil 2>&1 | grep package)
            if [ "$is_package" = "" ]; then
                wget --no-check-certificate -O $pyenv_path/pyenv/pip.txt $download_Url/install/pyenv/3.12/pip_en_3.12.txt -t 5 -T 15
                $pyenv_path/pyenv/bin/pip install -U pip
                $pyenv_path/pyenv/bin/pip install -U setuptools
                $pyenv_path/pyenv/bin/pip install -r $pyenv_path/pyenv/pip.txt
            fi
            source $pyenv_path/pyenv/bin/activate
            chmod -R 700 $pyenv_path/pyenv/bin
            return
        else
            rm -rf $pyenv_path/pyenv
        fi
    fi

    py_version="3.12.3"
    python_version="-3.12"
    mkdir -p $pyenv_path
    echo "True" >/www/disk.pl
    if [ ! -w /www/disk.pl ]; then
        Red_Error "ERROR: Install python env fielded." "ERROR: path [www] cannot be written, please check the directory/user/disk permissions!"
    fi
    os_type='el'
    os_version='7'
    # is_export_openssl=0
    Get_Versions
    echo "OS: $os_type - $os_version"
    is_aarch64=$(uname -m | grep aarch64)
    if [ "$is_aarch64" != "" ]; then
        is64bit="aarch64"
    fi
    if [ -f "/www/server/panel/pymake.pl" ]; then
        os_version=""
        rm -f /www/server/panel/pymake.pl
    fi
    if [ "${os_version}" != "" ]; then
        pyenv_file="/www/pyenv.tar.gz"
        wget --no-check-certificate -O $pyenv_file $download_Url/install/pyenv/3.12/pyenv-${os_type}${os_version}-x${is64bit}${python_version}.tar.gz -t 5 -T 15
        if [ "$?" != "0" ];then
            wget --no-check-certificate -O $pyenv_file $download_Url/install/pyenv/3.12/pyenv-${os_type}${os_version}-x${is64bit}${python_version}.tar.gz -t 5 -T 15
        fi
        tmp_size=$(du -b $pyenv_file | awk '{print $1}')
        if [ $tmp_size -lt 703460 ]; then
            rm -f $pyenv_file
            echo "ERROR: Download python env fielded."
        else
            echo "Install python env..."
            tar zxvf $pyenv_file -C $pyenv_path/ >/dev/null
            chmod -R 700 $pyenv_path/pyenv/bin
            if [ ! -f $pyenv_path/pyenv/bin/python ]; then
                Install_pyenv_fielded="yes"
                rm -f $pyenv_file
                Red_Error "ERROR: Install python env fielded. Please try again."
            fi
            $pyenv_path/pyenv/bin/python3.12 -V
            if [ $? -eq 0 ]; then
                rm -f $pyenv_file
                ln -sf $pyenv_path/pyenv/bin/pip3.12 /usr/bin/btpip
                ln -sf $pyenv_path/pyenv/bin/python3.12 /usr/bin/btpython
                source $pyenv_path/pyenv/bin/activate
                return
            else
                rm -f $pyenv_file
                rm -rf $pyenv_path/pyenv
            fi
        fi
    fi

    Get_Pack_Manager
    if [ "${PM}" = "yum" ]; then
        Install_RPM_Pack
    elif [ "${PM}" = "apt-get" ]; then
        Install_Deb_Pack
    fi

    cd /www
    python_src='/www/python_src.tar.xz'
    python_src_path="/www/Python-${py_version}"
    wget --no-check-certificate -O $python_src $download_Url/src/Python-${py_version}.tar.xz -t 5 -T 15
    tmp_size=$(du -b $python_src | awk '{print $1}')
    if [ $tmp_size -lt 10703460 ]; then
        Install_pyenv_fielded="yes"
        rm -f $python_src
        Red_Error "ERROR: Download python source code fielded. Please try again."
    fi
    tar xvf $python_src
    rm -f $python_src
    cd $python_src_path
    if [[ $Use_Openssl111 = "yes" ]]; then
        # centos7 或者低openssl于1.1.1使用
        export OPENSSL_DIR=/usr/local/openssl111
        ./configure --prefix=$pyenv_path/pyenv \
        LDFLAGS="-L$OPENSSL_DIR/lib" \
        CPPFLAGS="-I$OPENSSL_DIR/include" \
        --with-openssl=$OPENSSL_DIR
    else
        ./configure --prefix=$pyenv_path/pyenv
    fi

    make -j$cpu_cpunt
    make install
    if [ ! -f $pyenv_path/pyenv/bin/python3.12 ]; then
        rm -rf $python_src_path
        Install_pyenv_fielded="yes"
        Red_Error "ERROR: Make python env fielded. Please try again."
    fi
    cd ~
    rm -rf $python_src_path
    wget --no-check-certificate -O $pyenv_path/pyenv/bin/activate $download_Url/install/pyenv/activate.panel -t 5 -T 15
    wget --no-check-certificate -O $pyenv_path/pyenv/pip.txt $download_Url/install/pyenv/3.12/pip-3.12.3.txt -t 5 -T 15
    ln -sf $pyenv_path/pyenv/bin/pip3.12 $pyenv_path/pyenv/bin/pip
    ln -sf $pyenv_path/pyenv/bin/python3.12 $pyenv_path/pyenv/bin/python
    ln -sf $pyenv_path/pyenv/bin/pip3.12 /usr/bin/btpip
    ln -sf $pyenv_path/pyenv/bin/python3.12 /usr/bin/btpython
    chmod -R 700 $pyenv_path/pyenv/bin
    $pyenv_path/pyenv/bin/pip install -U pip
    $pyenv_path/pyenv/bin/pip install -U setuptools
    # $pyenv_path/pyenv/bin/pip install -U wheel==0.34.2
    $pyenv_path/pyenv/bin/pip install -r $pyenv_path/pyenv/pip.txt

    source $pyenv_path/pyenv/bin/activate
    btpip install psutil
    btpip install gevent
    is_gevent=$($python_bin -m gevent 2>&1 | grep -oE package)
    is_psutil=$($python_bin -m psutil 2>&1 | grep -oE package)
    if [ "${is_gevent}" != "${is_psutil}" ]; then
        Install_pyenv_fielded="yes"
        Red_Error "ERROR: psutil/gevent install failed! Please try again."
    fi
}

delete_useless_package() {
    /www/server/panel/pyenv/bin/pip uninstall aliyun-python-sdk-kms -y >/dev/null 2>&1
    /www/server/panel/pyenv/bin/pip uninstall aliyun-python-sdk-core -y >/dev/null 2>&1
    /www/server/panel/pyenv/bin/pip uninstall aliyun-python-sdk-core-v3 -y >/dev/null 2>&1
    /www/server/panel/pyenv/bin/pip uninstall qiniu -y >/dev/null 2>&1
    /www/server/panel/pyenv/bin/pip uninstall cos-python-sdk-v5 -y >/dev/null 2>&1
}

Upgrade_python312() {
    # 获取/www目录所在分区的可用空间（以KB为单位）
    available_kb=$(df -k /www | awk 'NR==2 {print $4}')

    # 1GB = 1024MB = 1024*1024KB
    available_gb=$((available_kb / 1024 / 1024))
    echo "/www partition currently available space: "$available_gb" G"

    # 判断可用空间是否小于1GB
    if [ "$available_gb" -lt 1 ]; then
        echo -e "\033[31m The available space is less than 1G.\033[0m"
        echo -e "\033[31m It is recommended to clean or upgrade the server space before upgrading.\033[0m"
        rm -f $Updating
        exit 1;
    fi
    # /etc/init.d/bt stop

    if [ -f /etc/init.d/bt_syssafe ]; then
        echo "Turning off System hardening"
        System_hardening="yes"
        /etc/init.d/bt_syssafe stop
        if [ -d "/etc/rc.d/" ]; then
            chattr -iaR /etc/rc.d/
        fi
        chattr -iaR /etc/init.d
    fi

    if [ -d "/www/server/panel/pyenv" ]; then
        echo "Backup old pyenv"

        if [ -d "/www/server/panel/pyenv_update-panel" ];then
            mv /www/server/panel/pyenv_update-panel /www/server/panel/pyenv_update-panel_$(date +%Y_%m_%d_%H_%M_%S)
        fi

        mv /www/server/panel/pyenv /www/server/panel/pyenv_update-panel
    fi
    Install_Python_Lib
    delete_useless_package

} 

Check_python_version() {
    is_loongarch64=$(uname -a | grep loongarch64)
    if [ "$is_loongarch64" != "" ]; then
        echo "loongarch64 does not currently support upgrades"
        rm -f $Updating
        exit
    fi
    if [ -f "/www/server/panel/pyenv/bin/python" ]; then

        get_python_version=$(/www/server/panel/pyenv/bin/python -V)
        if [[ ${get_python_version} =~ "Python 3.7." ]]; then
            echo ${get_python_version}
            Upgrade_python312
        else
            if [[ ${get_python_version} =~ "Python 3.12." ]]; then
                echo -e "Python3.12 No upgrade required"
            else
				Upgrade_python312
            fi
        fi
    else
        echo -e "/www/server/panel/pyenv/bin/python Does not exist, cannot determine python version"
        Upgrade_python312
    fi
}

Check_python_version

# mypip="pip"
# env_path=/www/server/panel/pyenv/bin/activate
# if [ -f $env_path ];then
# 	mypip="/www/server/panel/pyenv/bin/pip"
# fi
mypip="/www/server/panel/pyenv/bin/pip"

pip_list=$($mypip list)
setuptools_v=$(echo "$pip_list"|grep setuptools)
if [ "$setuptools_v" = "" ];then
	$mypip install setuptools
fi

requests_v=$(echo "$pip_list"|grep requests)
if [ "$requests_v" = "" ];then
	$mypip install requests
fi

openssl_v=$(echo "$pip_list"|grep pyOpenSSL)
if [ "$openssl_v" = "" ];then
	$mypip install pyOpenSSL
fi

pymysql=$(echo "$pip_list"|grep PyMySQL)
if [ "$pymysql" = "" ];then
	$mypip install PyMySQL
fi

GEVENT_V=$(echo "$pip_list"|grep "gevent "|awk '{print $2}'|cut -f 1 -d '.')
if [ "${GEVENT_V}" -le "1" ];then
    $mypip install -I gevent
fi

pycryptodome=$(echo "$pip_list"|grep pycryptodome)
if [ "$pycryptodome" = "" ];then
	$mypip install pycryptodome
fi

# $mypip install pyOpenSSL -I
# $mypip install python-telegram-bot==20.3
# $mypip install paramiko -I

telegram_v=$(echo "$pip_list"|grep python-telegram-bot)
if [ "$telegram_v" = "" ];then
	$mypip install python-telegram-bot==20.3
fi

if [ -f "/www/server/panel/plugin/linuxsys/linuxsys_main.py" ]; then
    distro_v=$(echo "$pip_list"|grep distro)
    if [ "$distro_v" = "" ];then
        $mypip install distro
    fi
fi

if [ -f "/www/server/panel/plugin/aws_s3/aws_s3_main.py" ]; then
    boto3_v=$(echo "$pip_list"|grep boto3)
    if [ "$boto3_v" = "" ];then
        $mypip install boto3
    fi
fi

if [ -f "/www/server/panel/plugin/frp/frp_main.py" ]; then
    toml_v=$(echo "$pip_list"|grep toml)
    if [ "$toml_v" = "" ];then
        $mypip install toml
    fi
fi

if [ -f "/www/server/panel/plugin/supervisor/supervisor_main.py" ]; then
    pyasynchat_v=$(echo "$pip_list"|grep pyasynchat)
    if [ "$pyasynchat_v" = "" ];then
        $mypip install pyasynchat
    fi
    Supervisor_plugin=/www/server/panel/plugin/supervisor
    Supervisor_py=/www/server/panel/pyenv/lib/python3.12/site-packages/supervisor

    if [ -d "$Supervisor_py" ]; then
        \cp -rpaf $Supervisor_py/options.py $Supervisor_plugin/options.py.bak
        \cp -rpaf $Supervisor_plugin/options.py $Supervisor_py/options.py

        \cp -rpaf $Supervisor_py/rpcinterface.py $Supervisor_plugin/rpcinterface.py.bak
        \cp -rpaf  $Supervisor_plugin/rpcinterface.py $Supervisor_py/rpcinterface.py
        echo bt > $Supervisor_py/bt.pl
    fi
fi

if [ -f "$setup_path/server/panel/pyenv/bin/python3.12" ] && [ ! -f "$setup_path/server/panel/data/upgrade_plugins_3.12.pl" ];then
    chmod +x $setup_path/server/panel/tools.py
    $setup_path/server/panel/pyenv/bin/python3 $setup_path/server/panel/tools.py upgrade_plugins
fi


if [[ $System_hardening == "yes" ]]; then
    echo "Turning on System hardening"
    /etc/init.d/bt_syssafe start
fi

only_update_pyenv312="/tmp/only_update_pyenv312.pl"
if [ -f "$only_update_pyenv312" ]; then
    Update_Py_Lib
    rm -f $Updating $only_update_pyenv312
    /etc/init.d/bt restart
    echo "$only_update_pyenv312 file exists, Only update Python3.12 environment complete!"
    exit 0;
fi

version='7.0.4'

check_version_num=$( echo "$version"|grep -Eo '^[0-9]+' )
if [ "$check_version_num" = '' ];then
	echo "Check version failed!"
    version='7.0.4'
fi

if [ "$version" = '' ];then
	version='7.0.4'
fi

# if [ "$1" ];then
# 	version="$1"
# fi


wget --no-check-certificate -t 5 -T 20 -O /tmp/panel.zip $download_Url/install/update/LinuxPanel_EN-${version}.zip

dsize=$(du -b /tmp/panel.zip|awk '{print $1}')
if [ $dsize -lt 10240 ];then
    echo "Failed to get update package, please update or contact aaPanel Operation"
    rm -f $Updating
    exit;
fi
unzip -o /tmp/panel.zip -d $setup_path/server/ > /dev/null
rm -f /tmp/panel.zip

Update_Py_Lib

cd $setup_path/server/panel/
check_bt=`cat /etc/init.d/bt`
if [ "${check_bt}" = "" ];then
    chattr -i /etc/init.d/bt
    rm -f /etc/init.d/bt
    wget --no-check-certificate -O /etc/init.d/bt $download_Url/install/src/bt7_en.init -t 5 -T 20
    chmod +x /etc/init.d/bt
fi
rm -f /www/server/panel/*.pyc
rm -f /www/server/panel/class/*.pyc


grep "www:x" /etc/passwd > /dev/null
if [ "$?" != 0 ];then
	Run_User="www"
	groupadd ${Run_User}
	useradd -s /sbin/nologin -g ${Run_User} ${Run_User}
fi
chattr -i /etc/init.d/bt
chmod +x /etc/init.d/bt
echo "====================================="
rm -f /dev/shm/bt_sql_tips.pl
process=$(ps aux|grep -E "task.pyc|main.py"|grep -v grep|awk '{print $2}')
if [ "$process" != "" ];then
	kill $process
fi
/etc/init.d/bt restart
# /etc/init.d/bt start
# echo 'True' > /www/server/panel/data/restart.pl
rm -f $Updating
echo "Successfully upgraded to[$version]${Ver}";
