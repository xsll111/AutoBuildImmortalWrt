#!/bin/bash
# Log file for debugging
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# 安装TurboACC加速（必须在make之前执行）
echo "$(date '+%Y-%m-%d %H:%M:%S') - 安装TurboACC加速组件..." >> $LOGFILE
(
    cd /home/build/immortalwrt
    curl -sSL https://raw.githubusercontent.com/chenmozhijin/turboacc/luci/add_turboacc.sh -o add_turboacc.sh
    bash add_turboacc.sh 2>&1 | tee -a $LOGFILE
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        echo "TurboACC安装失败!" >> $LOGFILE
        exit 1
    fi
)

echo "Create pppoe-settings"
mkdir -p /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

# 定义基础包列表（新增TurboACC相关包）
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES fdisk"
PACKAGES="$PACKAGES script-utils"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"

# TurboACC强制依赖包
PACKAGES="$PACKAGES luci-app-turboacc"
PACKAGES="$PACKAGES kmod-shortcut-fe"
PACKAGES="$PACKAGES kmod-fast-classifier"

# 条件添加Docker包
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn" >> $LOGFILE
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译，包含以下包:" >> $LOGFILE
echo "$PACKAGES" | tr ' ' '\n' >> $LOGFILE

make image \
    PROFILE="generic" \
    PACKAGES="$PACKAGES" \
    FILES="/home/build/immortalwrt/files" \
    ROOTFS_PARTSIZE=$PROFILE 2>&1 | tee -a $LOGFILE

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 编译失败!" >> $LOGFILE
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - 编译成功完成" >> $LOGFILE
