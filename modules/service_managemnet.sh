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
        if grep -E "^\s*disable\s*=\s*no" "/etc/xinetd.d/finger" 2>/dev/null; then
            result_fail "U-19 Finger 서비스 활성화: /etc/xinetd.d/finger 확인 (취약)"
            return
        fi
    fi

    result_pass "U-19 Finger 서비스 비활성화 (양호)"
}

# U-20 Anonymous FTP 비활성화
# vsftpd, proftpd, pure-ftpd 이외의 ftp 서버 프로그램에 대해서는 정밀 검사 X
check_anonymous_ftp() {
    if should_skip "U-20"; then
        return
    fi

    log_check_start "U-20" "for an anonymous FTP service"

    result_info "vsftpd, proftpd, pure-ftpd 이외의 FTP 서버를 사용하는 경우 설정 파일 수동 확인 필요"

    # vsftpd 설정 (/etc/vsftpd.conf)
    if [ -f /etc/vsftpd.conf ]; then
        if grep -E '^\s*anonymous_enable\s*=\s*YES' /etc/vsftpd.conf >/dev/null; then
            result_fail "U-20 vsftpd 설정: anonymous_enable=YES (취약)"
            return
        fi
    fi

    # proftpd 설정 (/etc/proftpd.conf)
    if [ -f /etc/proftpd.conf ]; then
        if grep -E '^\s*<Anonymous' /etc/proftpd.conf >/dev/null; then
            result_fail "U-20 proftpd 설정: <Anonymous> 블록 존재 (취약)"
            return
        fi
    fi

    # pure-ftpd 설정 (/etc/pure-ftpd/pure-ftpd.conf 또는 /etc/pure-ftpd.conf)
    for cfg in /etc/pure-ftpd/pure-ftpd.conf /etc/pure-ftpd.conf; do
        if [ -f "$cfg" ] && grep -E '^\s*NoAnonymous\s*=\s*0' "$cfg" >/dev/null; then
            result_fail "U-20 pure-ftpd 설정: NoAnonymous=0 (취약)"
            return
        fi
    done

    # /etc/passwd에 ftp 사용자 확인
    if grep -E "^ftp:" "/etc/passwd" 2>/dev/null; then
        result_fail "U-20 Anonymous FTP 접속에 사용될 수 있는 ftp User 존재 (취약)"
        return
    fi

    result_pass "U-20 Anonymous FTP 비활성화"
}

check_finger_service
check_anonymous_ftp