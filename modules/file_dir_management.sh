#!/bin/bash
#
# file_dir_management.sh
# Description: KISA 주요정보통신기반시설 Linux 서버 취약점 진단 가이드 중 파일/디렉터리 관리 파트 진단 모듈
#

# U-05 root 홈, 패스 디렉터리 권한 및 패스 설정
check_root_path() {
    
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