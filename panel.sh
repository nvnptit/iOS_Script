#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
LANG=en_US.UTF-8

# Định nghĩa phiên bản cần cài đặt
version='7.0.4'

# Kiểm tra xem người dùng có phải là root không
if [ $(whoami) != "root" ]; then
    echo -e "Không phải quyền root, vui lòng thử các giải pháp sau: \n   1. Chuyển sang người dùng [root] để cài đặt \n   2. Thử chạy lệnh sau: \n     sudo bash $0 $@"
    exit 1
fi

# Đảm bảo hệ thống là 64-bit
is64bit=$(getconf LONG_BIT)
if [ "${is64bit}" != '64' ]; then
    echo "Xin lỗi, aaPanel không hỗ trợ hệ thống 32-bit"
    exit 1
fi

# Kiểm tra các hệ điều hành không được hỗ trợ
if [ -f "/etc/SUSE-brand" ]; then
    openSUSE_check=$(cat /etc/SUSE-brand | grep openSUSE)
    if [ "${openSUSE_check}" ]; then
        echo "Lỗi: openSUSE không được hỗ trợ. Khuyến nghị bạn sử dụng: Debian 11/12, Ubuntu 20/22/24, Rocky/Alma 8, Rocky/Alma/Centos 9"
        exit 1
    fi
fi

# Thiết lập đường dẫn cài đặt
setup_path="/www"
python_bin=$setup_path/server/panel/pyenv/bin/python
cpu_cpunt=$(cat /proc/cpuinfo | grep ^processor | wc -l)

# Hàm lấy thông tin hệ thống để hỗ trợ gỡ lỗi
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
    echo -e "Vui lòng chụp màn hình lỗi trên và đăng lên diễn đàn forum.aapanel.com để được hỗ trợ"
}

# Hàm xử lý lỗi
Red_Error() {
    echo '================================================='
    printf '\033[1;31;40m%b\033[0m\n' "$@"
    GetSysInfo
    exit 1
}

# Kiểm tra dung lượng đĩa trống
Check_Disk_Space() {
    available_kb=$(df -k /www | awk 'NR==2 {print $4}')
    available_gb=$((available_kb / 1024 / 1024))
    echo "Dung lượng đĩa trống trên phân vùng cài đặt: "$available_gb" G"
    if [ "$available_gb" -lt 1 ]; then
        Red_Error "Dung lượng trống ít hơn 1GB. Khuyến nghị dọn dẹp hoặc nâng cấp không gian lưu trữ trước khi cài đặt."
    fi
}

# Hàm xác định trình quản lý gói
Get_Pack_Manager() {
    if [ -f "/usr/bin/yum" ] && [ -d "/etc/yum.repos.d" ]; then
        PM="yum"
    elif [ -f "/usr/bin/apt-get" ] && [ -f "/usr/bin/dpkg" ]; then
        PM="apt-get"
    fi
}

# Cài đặt các gói cần thiết cho CentOS/RHEL
Install_RPM_Pack() {
    yum install -y wget curl libcurl-devel tar gcc make zip unzip openssl openssl-devel lsof
}

# Cài đặt các gói cần thiết cho Debian/Ubuntu
Install_Deb_Pack() {
    apt-get update -y
    apt-get install -y wget curl libcurl4-openssl-dev gcc make zip unzip tar openssl libssl-dev lsof
}

# Kiểm tra và cài đặt các gói cần thiết
Install_Packages() {
    Get_Pack_Manager
    if [ "${PM}" = "yum" ]; then
        Install_RPM_Pack
    elif [ "${PM}" = "apt-get" ]; then
        Install_Deb_Pack
    fi
}

# Tải và cài đặt phiên bản 7.0.4
Install_Version_7_0_4() {
    echo "Đang tải xuống aaPanel phiên bản $version ..."
    wget --no-check-certificate -t 5 -T 20 -O /tmp/panel.zip https://node.aapanel.com/install/update/LinuxPanel_EN-${version}.zip

    dsize=$(du -b /tmp/panel.zip | awk '{print $1}')
    if [ $dsize -lt 10240 ]; then
        Red_Error "Không tải được gói cập nhật, vui lòng cập nhật hoặc liên hệ với hỗ trợ aaPanel"
    fi

    echo "Đang cài đặt aaPanel phiên bản $version ..."
    unzip -o /tmp/panel.zip -d $setup_path/server/ > /dev/null
    rm -f /tmp/panel.zip

    echo "Cài đặt thành công aaPanel phiên bản $version"
}

# Thực thi cài đặt
Check_Disk_Space
Install_Packages
Install_Version_7_0_4

echo "Hoàn tất cài đặt thành công."
