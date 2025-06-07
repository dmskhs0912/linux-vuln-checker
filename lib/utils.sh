#!/bin/bash
#
# utils.sh
# Description: 공용 함수 정의
#

# PASS 결과 처리 함수
# 인자로는 “항목 식별자 + 메시지” 형태의 문자열을 받는다
result_pass() {
  local message="$1"
  message=$(printf "\e[32m[PASS]\e[0m %s\n" "$message")
  # 전역 배열에 메시지를 추가
  PASSED+=("$message")
  TOTAL_RESULT+=("$message")
}

# FAIL 결과 처리 함수
result_fail() {
  local message="$1"
  message=$(printf "\e[31m[FAIL]\e[0m %s\n" "$message")
  FAILED+=("$message")
  TOTAL_RESULT+=("$message")
}

result_info() {
  local message="$1"
  printf "\e[97m[INFO]\e[0m %s\n" "$message" 
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

# 로그 헬퍼 
log_check_start() {
  local id="$1"       
  local message="$2"  
  printf "%s Checking %s…\n" "[$id]" "$message"
}

# exclude.conf로부터 검사 제외 항목 로드
load_excludes() {

  while IFS= read -r line; do
    if [[ -z "$line" || "$line" =~ ^# ]]; then
      continue # 주석, 빈줄 제외
    fi
    EXCLUDE_CHECKS+=( "$line" )
  done < "$EXCLUDE_CONFIG"
}

# 검사 제외 항목이면 0 반환
should_skip() {
  local id="$1"

  for skip in "${EXCLUDE_CHECKS[@]}"; do
    if [[ "$skip" == "$id" ]]; then
      result_info "$id 검사 제외됨 (config에서 설정됨)"
      return 0
    fi
  done
  
  return 1
}