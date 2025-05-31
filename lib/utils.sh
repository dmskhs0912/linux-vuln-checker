#!/bin/bash
#
# utils.sh
# Description: 공용 함수 정의
#

# PASS 결과 처리 함수
# 인자로는 “항목 식별자 + 메시지” 형태의 문자열을 받는다
result_pass() {
  local message="$1"
  printf "\e[32m[PASS]\e[0m %s\n" "$message"
  # 전역 배열에 메시지를 추가
  PASSED+=("$message")
  TOTAL_RESULT+=("$message")
}

# FAIL 결과 처리 함수
result_fail() {
  local message="$1"
  printf "\e[31m[FAIL]\e[0m %s\n" "$message"
  FAILED+=("$message")
  TOTAL_RESULT+=("$message")
}