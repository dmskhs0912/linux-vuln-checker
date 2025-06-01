#!/bin/bash
#
# account_management.sh
# Description: KISA 주요정보통신기반시설 Linux 서버 취약점 진단 가이드 중 계정 관리 파트 진단 모듈
#

check_root_remote_login() {
    local ssh_ok=true
    local telnet_ok=true

    # SSH root 원격 접속 허용 확인
    if [-f /etc/ssh/sshd_config]; then
        if grep -Eq "^\s*PermitRootLogin\s+no" /etc/ssh/sshd_config; then
            :
        else
            ssh_ok=false
        fi
    fi

    # Telnet 설정 확인 (securetty)
    if [ -f /etc/securetty ]; then
        # /etc/securetty 파일에 pts/ 항목이 없거나 주석 처리되어야 함
        if grep -Eq '^pts/' /etc/securetty; then
            tty_ok=false
        fi
    fi

    if $ssh_ok; then
        result_pass "U-01 root 계정 SSH 접속 제한"
    else
        result_fail "U-01 root 계정 SSH 접속 제한"
    fi

    if $telnet_ok; then
        result_pass "U-01 root 계정 Telnet 접속 제한"
    else
        result_fail "U-01 root 계정 Telnet 접속 제한"
    fi
}

