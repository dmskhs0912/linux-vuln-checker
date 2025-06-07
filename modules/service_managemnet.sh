#!/bin/bash
#
# file_dir_management.sh
# Description: KISA 주요정보통신기반시설 Linux 서버 취약점 진단 가이드 중 파일/디렉터리 관리 파트 진단 모듈
#

# U-19 Finger 서비스 비활성화
check_finger_service() {
    if should_skip "U-19"; then
        return
    fi

    log_check_start "U-19" "for a active finger daemon service"

    # /etc/inetd.conf 먼저 확인
    if [ -f /etc/inetd.conf ]; then
        if grep -E "^\s*finger" "/etc/inetd.conf" 2>/dev/null; then
            result_fail "U-19 Finger 서비스 활성화: /etc/inetd.conf 확인 (취약)"
            return
        fi
    fi

    # /etc/xinetd.d/finger 확인
    if [ -f /etc/xinetd.d/finger ]; then
        if grep -E "^\s*disable\s*=\s*no" "/etc/xinetd.d/finger"; then
            result_fail "U-19 Finger 서비스 활성화: /etc/xinetd.d/finger 확인 (취약)"
            return
        fi
    fi

    result_pass "U-19 Finger 서비스 비활성화 (양호)"
}


check_finger_service