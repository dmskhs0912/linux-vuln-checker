#!/bin/bash
#
# report.sh
# Description: PASSED와 FAILED 배열 기반으로 취약점 진단 결과를 요약 및 출력하고 파일로 저장
# Usage: 
#

generate_timestamp() {
    date +'%Y-%m-%dT%H%M%S'   
}

HOSTNAME=$(hostname)
TIMESTAMP=$(generate_timestamp)

# 리포트용 문자열 생성
REPORT_HEADER="\
===================================================================
Linux Vulnerability Assessment Report
===================================================================
진단 일시    : ${TIMESTAMP}
호스트명      : ${HOSTNAME}
운영체제 정보 : ${OS_ID} ${OS_VERSION} (${OS_LIKE} 계열)
-------------------------------------------------------------------
총 점검 항목 : $(( ${#PASSED[@]} + ${#FAILED[@]} ))개
  ✔ PASS    : ${#PASSED[@]}개
  ✖ FAIL    : ${#FAILED[@]}개
===================================================================
"

# 전체 결과 요약 출력
echo "$REPORT_HEADER"

# FAIL 상세 출력
if [ ${#FAILED[@]} -gt 0 ]; then
  echo "❗ 취약 항목 상세:"
  for msg in "${FAILED[@]}"; do
    echo "  - ${msg}"
  done
  echo "==================================================================="
else
  echo "✅ 모든 항목이 양호합니다."
  echo "==================================================================="
fi

# 결과 저장 파일 설정 (reports 디렉터리 없으면 생성)
OUTPUT_DIR="$(dirname "$0")/reports"
mkdir -p "$OUTPUT_DIR"

# 텍스트 로그 생성
LOG_FILE="${OUTPUT_DIR}/vuln_report_${TIMESTAMP}.log"
{
  echo "$REPORT_HEADER"
  if [ ${#FAILED[@]} -gt 0 ]; then
    echo "❗ 취약 항목 상세:"
    for msg in "${FAILED[@]}"; do
      echo "  - ${msg}"
    done
  else
    echo "✅ 모든 항목 양호"
  fi
} > "$LOG_FILE"