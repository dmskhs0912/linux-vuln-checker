#!/bin/bash
#
# vuln_check.sh
# Description: KISA에서 제공한 2021 주요정보통신기반시설 취약점 분석 가이드를 기반으로 한 Linux 서버 취약점 진단 스크립트
# Usage: /path/to/vuln_check.sh
#

EXCLUDE_CONFIG="./config/exclude.conf"

# 결과 집계용 전역 배열 선언 (/lib/report.sh에서 사용)
PASSED=()
FAILED=()
TOTAL_RESULT=()

# 검사 제외 항목
EXCLUDE_CHECKS=()

# 시스템의 리눅스 배포판, 버전, 패키지 매니저, 서비스 관리 방식 등 감지 후 변수에 저장
source "$(dirname "$0")/lib/os_detection.sh"

# 공용 함수 선언 및 정의
source "$(dirname "$0")/lib/utils.sh"
load_excludes

# 각 검사 모듈 실행
source "$(dirname "$0")/modules/account_management.sh"
source "$(dirname "$0")/modules/file_dir_management.sh"
source "$(dirname "$0")/modules/service_management.sh"

# 결과 요약 출력 및 결과 파일 저장
source "$(dirname "$0")/lib/report.sh"