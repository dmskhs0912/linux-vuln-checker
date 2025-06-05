#!/bin/bash
#
# file_dir_management.sh
# Description: KISA 주요정보통신기반시설 Linux 서버 취약점 진단 가이드 중 파일/디렉터리 관리 파트 진단 모듈
#

# U-05 root 홈, 패스 디렉터리 권한 및 패스 설정
check_root_path() {
    log_check_start "U-05" "for root's PATH environment variable"

    if echo "$PATH" | grep -Eq '^[.:]'; then
        result_fail "U-05 root 계정의 PATH가 . 또는 ::으로 시작함 (취약)"
        return
    elif echo "$PATH" | grep -Eq '::'; then
        result_fail "U-05 root 계정의 PATH 중간에 빈 항목(::)이 있음 (취약)"
        return
    elif echo "$PATH" | grep -Eq ':\.'; then
        result_fail "U-05 root 계정의 PATH 중간에 상대경로 포함 (취약)"
    else
        result_pass "U-05 root 계정의 PATH에 빈 항목이나 상대경로 미포함 (양호)"
    fi

}

# U-06 파일 및 디렉터리 소유자 설정 (소유자가 존재하지 않는 파일/디렉터리 검사)
check_nouser_files() {
    log_check_start "U-06" "for files/directories without a valid owner"

    local root_fs files count sample_list

    # 소유자가 없는 모든 파일 및 디렉터리를 찾아 경로만 출력
    files=$(find / -xdev -nouser -print 2>/dev/null)

    # 결과 개수 세기
    count=$(printf "%s\n" "$files" | grep -c .)

    if [ "$count" -eq 0 ]; then
        result_pass "U-06 소유자가 없는 파일/디렉터리 존재하지 않음 (양호)"
    else
        # 소유자가 없는 파일/디렉터리 5개만 예시 출력 
        sample_list=$(printf "%s\n" "$files" | head -n 5 | paste -sd "," -)
        result_fail "U-06 소유자가 없는 파일/디렉터리 ${count}개 발견 (취약). 예시: ${sample_list}"
    fi
}

# 파일 소유자/권한 검사용 함수
# Usage: check_owner_perm "검사할 파일" "기준 소유자" 기준권한(정수)
# 취약: 0 / 양호(둘다 일치): 1 / 소유자 양호, 기준 권한 이하로 설정: 2 리턴
check_owner_perm() {
    local file_path="$1"
    local kisa_owner="$2"
    local kisa_perm="$3"

    # 존재하지 않는 파일이면 양호(1) 리턴
    if [ ! -e "$file_path" ]; then
        return 1
    fi

    # 실제 파일의 소유자/권한
    local owner=$(stat -c "%U" "$file_path")
    local perm=$(stat -c "%a" "$file_path")

    if [[ "$owner" == "$kisa_owner" ]]; then
        if [[ "$perm" -eq "$kisa_perm" ]]; then
            return 1
        elif [[ "$perm" -le "$kisa_perm" ]]; then
            return 2
        fi
    fi

    return 0
}

# U-07 /etc/passwd 파일 소유자 및 권한 설정 
check_passwd_owner() {
    log_check_start "U-07" "for a owner and a permission of /etc/passwd file"
    
    check_owner_perm "/etc/passwd" "root" 644
    local rc=$?

    if [ $rc -ge 1 ]; then
        result_pass "U-07 /etc/passwd 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-07 /etc/passwd 파일의 소유자 또는 권한이 기준(root/644 이하)에 맞지 않음 (취약)"
    fi
}

# U-08 /etc/shadow 파일 소유자 및 권한 설정
check_shadow_owner() {
    log_check_start "U-08" "for a owner and a permission of /etc/shadow file"

    check_owner_perm "/etc/shadow" "root" 400
    local rc=$?

    if [ $rc -ge 1 ]; then
        result_pass "U-08 /etc/shadow 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-08 /etc/shadow 파일의 소유자 또는 권한이 기준(root/400 이하)에 맞지 않음 (취약)"
    fi
}

# U-09 /etc/hosts 파일 소유자 및 권한 설정
check_hosts_owner() {
    log_check_start "U-09" "for a owner and a permission of /etc/hosts file"

    check_owner_perm "/etc/hosts" "root" 600
    local rc=$?

    if [ $rc -ge 1 ]; then
        result_pass "U-09 /etc/hosts 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-09 /etc/hosts 파일의 소유자 또는 권한이 기준(root/600 이하)에 맞지 않음 (취약)"
    fi
}

# U-10 /etc/(x)inetd.conf 파일 소유자 및 권한 설정
check_inetd_owner() {
    log_check_start "U-10" "for owners and permissions of /etc/(x)inetd.conf and /etc/xinet.d/"
    
    local files_to_check=()
    local owner
    local perm

    # inetd 관련 파일/디렉터리 존재 확인
    if [ -f /etc/inetd.conf ]; then
        files_to_check+=( "/etc/inetd.conf" )
    fi

    if [ -f /etc/xinetd.conf ]; then
        files_to_check+=( "/etc/xinetd.conf" )
    fi

    if [ -d /etc/xinetd.d ]; then
        for f in /etc/xinet.d/*; do
            [ -f "$f" ] && files_to_check+=( "$f" )
        done
    fi

    # 해당 파일/디렉터리 없는 경우 양호
    if [ ${#files_to_check[@]} -eq 0 ]; then
        result_pass "U-10 슈퍼 데몬 관련 파일 없음 (양호)"
        return
    fi

    for target in "${files_to_check[@]}"; do
        check_owner_perm "$target" "root" 600
        local rc=$?

        if [ $rc -ne 1 ]; then
            result_fail "U-10 $target 파일의 소유자 또는 권한이 기준(root/600)에 맞지 않음 (취약)"
            return
        fi
    done

    result_pass "U-10 슈퍼 데몬 관련 파일의 소유자와 권한이 적절하게 설정되어 있음 (양호)"
}

# U-11 /etc/syslog.conf 파일 소유자 및 권한 설정
check_syslog_owner() {
    log_check_start "U-11" "for a owner and a permission of /etc/syslog.conf file"

    check_owner_perm "/etc/syslog.conf" "root" 644
    local rc1=$?
    check_owner_perm "/etc/syslog.conf" "bin" 644
    local rc2=$?
    check_owner_perm "/etc/syslog.conf" "sys" 644
    local rc3=$?

    if [[ $rc1 -ge 1 || $rc2 -ge 1 || $rc3 -ge 1 ]]; then
        result_pass "U-11 /etc/syslog.conf 파일의 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-11 /etc/syslog.conf 파일의 소유자 및 권한이 기준에 맞지 않음 (취약)"
    fi
}

check_root_path
# ------------------- 오래 걸려서 디버깅 용으로 잠시 주석 처리 -------------------
#check_nouser_files 
# ------------------------------------------------------------------------------
check_passwd_owner
check_shadow_owner
check_hosts_owner
check_inetd_owner
check_syslog_owner