#!/bin/bash
#
# os_detection.sh
# Description: 현재 시스템의 배포판, 버전, 패키지 매니저, 서비스 관리 방식을 감지하여 변수에 저장
# Usage: source /path/to/os_detection.sh
#

# 1. /etc/os-release 파싱
if [ -r /etc/os-release ]; then
    # /etc/os-release 파일에서 ID, ID_LIKE, VERSION_ID 추출
    . /etc/os-release
    OS_ID="${ID,,}"            # 예: ubuntu, centos, rhel
    OS_LIKE="${ID_LIKE,,}"     # 예: debian, rhel
    OS_VERSION="${VERSION_ID}" # 예: 20.04, 7, 15.1
else
    echo "[ERROR] /etc/os-release 파일을 찾을 수 없습니다. 수동 점검 필요."
    exit 1
fi

# 2. 어떤 계열인지 플래그 설정 (true/false)
IS_DEBIAN=false
IS_UBUNTU=false
IS_CENTOS=false
IS_RHEL=false

# ID나 ID_LIKE 값을 보고 계열 판별
case "${OS_ID}" in
    ubuntu)
        IS_UBUNTU=true
        IS_DEBIAN=true
        ;;
    debian)
        IS_DEBIAN=true
        ;;
    centos)
        IS_CENTOS=true
        ;;
    rhel | "redhat" )
        IS_RHEL=true
        ;;
esac

# 만약 ID_LIKE 정보에 debian/rhel 등이 포함되어 있으면 플래그 보완
# ex) Linux Mint 등 ID_LIKE=debian인 경우도 고려
if [[ "${OS_LIKE}" =~ "debian" ]]; then
    IS_DEBIAN=true
fi
if [[ "${OS_LIKE}" =~ "rhel" ]]; then
    IS_RHEL=true
fi

# 3. 패키지 매니저 결정
#    - Debian/Ubuntu 계열: apt, apt-get
#    - CentOS/RHEL 계열: yum (RHEL7 이하) 또는 dnf (RHEL8 이상)
if $IS_DEBIAN; then
    PKG_MGR="apt-get"
elif $IS_UBUNTU; then
    PKG_MGR="apt-get"   # Ubuntu 20.04 이상은 apt 사용 가능하나 호환성 위해 apt-get
elif $IS_CENTOS || $IS_RHEL; then
    # RHEL/CentOS 8 이상이면 dnf 사용
    if command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    else
        PKG_MGR="yum"
    fi
else
    PKG_MGR="unknown"
fi

# 4. 서비스 관리 명령 결정 (systemd vs sysvinit)
#    - systemd: systemctl
#    - sysvinit: service
if command -v systemctl &>/dev/null; then
    SERVICE_CMD="systemctl"
else
    SERVICE_CMD="service"
fi

# 5. 결과 요약 출력 (디버깅용)
#echo "========================================"
#echo "[OS Detection]"
#echo "OS_ID       : ${OS_ID}"
#echo "OS_LIKE     : ${OS_LIKE}"
#echo "OS_VERSION  : ${OS_VERSION}"
#echo "Family Flags: DEBIAN=${IS_DEBIAN}, UBUNTU=${IS_UBUNTU}, CENTOS=${IS_CENTOS}, RHEL=${IS_RHEL}"
#echo "Package Mgr : ${PKG_MGR}"
#echo "Service Cmd : ${SERVICE_CMD}"
#echo "========================================"

# 6. 외부에서 참조할 수 있도록 환경 변수로 export (필요시)
export OS_ID OS_LIKE OS_VERSION
export IS_DEBIAN IS_UBUNTU IS_CENTOS IS_RHEL IS_SUSE
export PKG_MGR SERVICE_CMD
