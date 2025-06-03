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

# U-07 /etc/passwd 파일 소유자 및 권한 설정 
check_passwd_owner() {
    log_check_start "U-07" "for a owner and a permission of /etc/passwd file"
    
    local owner=$(stat -c "%U" "/etc/passwd")
    local perm=$(stat -c "%a" "/etc/passwd")

    if [[ "$owner" != "root" ]]; then
        result_fail "U-07 /etc/passwd 파일의 소유자가 root가 아닌 ${$owner}로 되어 있음 (취약)"
        return
    fi

    if [[ "$perm" -le 644 ]]; then
        result_pass "U-07 /etc/passwd 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-07 /etc/passwd 파일의 권한이 644 이하가 아님 (취약)"
    fi

}

check_root_path
check_nouser_files
check_passwd_owner