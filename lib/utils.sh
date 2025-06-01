#!/bin/bash
#
# utils.sh
# Description: 공용 함수 정의
#

# PASS 결과 처리 함수
# 인자로는 “항목 식별자 + 메시지” 형태의 문자열을 받는다
result_pass() {
  local message="$1"
  printf "\e[32m[PASS]\e[0m %s\n" "$message" > /dev/null
  # 전역 배열에 메시지를 추가
  PASSED+=("$message")
  TOTAL_RESULT+=("$message")
}

# FAIL 결과 처리 함수
result_fail() {
  local message="$1"
  printf "\e[31m[FAIL]\e[0m %s\n" "$message" > /dev/null
  FAILED+=("$message")
  TOTAL_RESULT+=("$message")
}

# PAM 모듈 존재 여부 검사 및 경로 리턴 함수
# Usage: get_pam_module_path module_name
get_pam_module_path() {
  local module_name="$1"
  local module_path=""
  for dir in \
    "/lib/security" \
    "/lib64/security" \
    "/usr/lib/security" \
    "/usr/lib64/security" \
    "/usr/lib/x86_64-linux-gnu/security" \
    "/usr/lib/i386-linux-gnu/security" \
    "/usr/lib/$(uname -m)-linux-gnu/security" \
  ; do
    if [ -f "$dir/$module_name" ]; then
      module_path="$dir/$module_name"
      break
    fi
  done

  echo "$module_path"
}