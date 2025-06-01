#!/bin/bash
#
# account_management.sh
# Description: KISA 주요정보통신기반시설 Linux 서버 취약점 진단 가이드 중 계정 관리 파트 진단 모듈
#

# U-01 root 원격 접속 제한
check_root_remote_login() {
    local ssh_ok=true
    local telnet_ok=true

    # SSH root 원격 접속 허용 확인
    if [ -f /etc/ssh/sshd_config ]; then
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
            telnet_ok=false
        fi
    fi

    if $ssh_ok; then
        result_pass "U-01 root 계정 SSH 접속이 제한되어 있음 (양호)"
    else
        result_fail "U-01 root 계정 SSH 접속이 제한되어 있지 않음 (취약)"
    fi

    if $telnet_ok; then
        result_pass "U-01 root 계정 Telnet 접속이 제한되어 있음 (양호)"
    else
        result_fail "U-01 root 계정 Telnet 접속 제한되어 있지 않음 (취약)"
    fi
}

# U-02 패스워드 복잡성 설정 (PAM 모듈 및 정책 진단)
# TODO: pam_cracklib.so 모듈 사용하는 경우 처리 필요요
check_password_complexity() {
    local module_path=""
    local policy_path="/etc/pam.d/common-password"

    # 1) pwquality.so 존재 검사 (후보 디렉터리 배열)
    for dir in \
        "/lib/security" \
        "/lib64/security" \
        "/usr/lib/security" \
        "/usr/lib64/security" \
        "/usr/lib/x86_64-linux-gnu/security" \
        "/usr/lib/i386-linux-gnu/security" \
        "/usr/lib/$(uname -m)-linux-gnu/security" \
    ; do
    if [ -f "$dir/pam_pwquality.so" ]; then
        module_path="$dir/pam_pwquality.so"
        break
    fi
    done

    # 모듈 미설치시 취약
    if [ -n "$module_path" ]; then
        :
    else
        result_fail "U-02 패스워드 복잡성 관련 PAM 모듈 (pam_pwquality.so) 미설치 (취약)"
        return
    fi

    # 2) common-password PAM 정책 검사
    if [ -f "$policy_path" ]; then
        # pam_pwquality.so 호출 줄 가져오기
        local line
        line=$(grep -E 'pam_pwquality\.so' "$policy_path" | head -n1)

        if [ -z "$line" ]; then
            result_fail "U-02 $policy_path에 pam_pwquality.so 호출 없음 (취약)"
            return
        fi

        # 검증해야 할 파라미터 리스트 (KISA 권장 값)
        local params=( \
            "retry=3" \
            "minlen=8" \
            "difok=7" \
            "ucredit=-1" \
            "lcredit=-1" \
            "dcredit=-1" \
            "ocredit=-1" \
            "enforce_for_root" \
        )

        # 모든 파라미터가 포함되어 있는지 확인
        local missing=false
        local p
        for p in "${params[@]}"; do
            if [[ "$line" != *"$p"* ]]; then
                missing=true
                break
            fi
        done

        if ! $missing; then
            result_pass "U-02 $policy_path 패스워드 복잡성 설정: $line (양호)"
        else
            result_fail "U-02 $policy_path 권장 파라미터 누락 (취약): $line"
        fi
    else
        result_fail "U-02 패스워드 복잡성 관련 PAM 정책 $policy_path 없음 (취약)"
    fi
}


check_root_remote_login
check_password_complexity