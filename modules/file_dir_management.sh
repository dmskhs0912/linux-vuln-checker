#!/bin/bash
#
# file_dir_management.sh
# Description: KISA 주요정보통신기반시설 Linux 서버 취약점 진단 가이드 중 파일/디렉터리 관리 파트 진단 모듈
#

# U-05 root 홈, 패스 디렉터리 권한 및 패스 설정
check_root_path() {
    if should_skip "U-05"; then
        return
    fi

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
    if should_skip "U-06"; then
        return
    fi

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
    if should_skip "U-07"; then
        return
    fi

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
    if should_skip "U-08"; then
        return
    fi

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
    if should_skip "U-09"; then
        return
    fi

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
    if should_skip "U-10"; then
        return
    fi

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
    if should_skip "U-11"; then
        return
    fi

    log_check_start "U-11" "for a owner and a permission of /etc/syslog.conf file"

    local file_path="/etc/syslog.conf"

    check_owner_perm "$file_path" "root" 644
    local rc1=$?
    check_owner_perm "$file_path" "bin" 644
    local rc2=$?
    check_owner_perm "$file_path" "sys" 644
    local rc3=$?

    if [[ $rc1 -ge 1 || $rc2 -ge 1 || $rc3 -ge 1 ]]; then
        result_pass "U-11 /etc/syslog.conf 파일의 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-11 /etc/syslog.conf 파일의 소유자 및 권한이 기준에 맞지 않음 (취약)"
    fi
}

# U-12 /etc/services 파일 소유자 및 권한 설정
check_services_owner() {
    if should_skip "U-12"; then
        return
    fi

    log_check_start "U-12" "for a owner and a permission of /etc/services file"

    local file_path="/etc/services"

    check_owner_perm "$file_path" "root" 644
    local rc1=$?
    check_owner_perm "$file_path" "bin" 644
    local rc2=$?
    check_owner_perm "$file_path" "sys" 644
    local rc3=$?

    if [[ $rc1 -ge 1 || $rc2 -ge 1 || $rc3 -ge 1 ]]; then
        result_pass "U-12 /etc/services 파일의 소유자 및 권한이 적절하게 설정되어 있음 (양호)"
    else
        result_fail "U-12 /etc/services 파일의 소유자 및 권한이 기준에 맞지 않음 (취약)"
    fi
}

# U-13 특수 권한 파일 점검
# 이후 구현

# U-14 사용자, 시스템 시작 파일 및 환경 파일 소유자 및 권한 설정
check_env_file_owner() {
    if should_skip "U-14"; then
        return
    fi

    log_check_start "U-14" "for owners and permissions of each environment variable files"

    # config과 연결해서 사용하면 좋을듯. 나중에 구현 
    local files_to_check=(
        ".bash_profile"
        ".bashrc"
        ".profile"
    )
    local vuln_files=()

    # /etc/passwd 파일에서 각 사용자 파싱
    while IFS=: read -r username _ uid _ _ home _; do
        if [[ "$uid" -ge 1000 && -d "$home" ]]; then
            for ufile in "${files_to_check[@]}"; do
                local fullpath="$home/$ufile"
                
                # 없으면 스킵
                if [ ! -e "$fullpath" ]; then
                    continue
                fi

                check_owner_perm "$fullpath" "$username" 644
                local rc=$?
                if [ $rc -eq 0 ]; then
                    vuln_files+=( "$fullpath" )
                fi
            done
        fi
    done < /etc/passwd

    if [ ${#vuln_files[@]} -gt 0 ]; then
        local joined=$(IFS=','; echo "${vuln_files[*]}")
        result_fail "U-14 사용자 환경 변수 파일 소유자 또는 권한이 적절하지 않음 (취약): $joined"
    else
        result_pass "U-14 사용자 환경 변수 파일 소유자 또는 권한이 적절하게 설정되어 있음 (양호)"
    fi
}

# U-15 world writable 파일 점검
# 필요한 world writable 파일을 어떻게 구분할지? config과 연동할지 고민 후 구현

# 파일이 디바이스 노드인지 확인
is_device_node() {
    local file_path="$1"
    
    if [[ -b "$file_path" || -c "$file_path" ]]; then
        return 0
    else
        return 1
    fi
}

# 디바이스 노드의 major, minor 번호를 꺼내 실제 sysfs에 존재하는 디바이스인지 확인
device_exists_in_sysfs() {
    local file_path="$1"
    local hexmaj hexmin maj min

    read -r hexmaj hexmin < <(stat -c "%t %T" "$file_path" 2>/dev/null)
    if [[ -z "$hexmaj" || -z "$hexmin" ]]; then
        return 1
    fi

    # major, minor 값 10진수 변환
    maj=$((0x$hexmaj))
    min=$((0x$hexmin))

    # 블록 디바이스
    if [ -b "$file_path" ]; then
        if [ -e "/sys/dev/block/${maj}:${min}" ]; then
            return 0
        else
            return 1
        fi
    fi

    # 문자 디바이스
    if [ -c "$file_path" ]; then
        if [ -e "/sys/dev/char/${maj}:${min}" ]; then
            return 0
        else
            return 1
        fi
    fi  

    return 0
}

# U-16 /dev에 존재하지 않는 device 파일 점검
check_dev() {
    if should_skip "U-16"; then
        return
    fi

    log_check_start "U-16" "for a invalid device file in /dev"

    local vuln_list=()

    while IFS= read -r -d '' f; do
        # 심볼릭 링크, 디렉터리 제외
        if [[ -L "$f" || -d "$f" ]]; then
            continue
        fi

        # 디바이스 노드가 맞는지 확인
        if ! is_device_node "$f"; then
            vuln_list+=( "$f (디바이스 아님)" )
            continue
        fi

        # sysfs에 존재하는지 확인
        if ! device_exists_in_sysfs "$f"; then
            vuln_list+=( "$f (sysfs에 존재하지 않음)" )
        fi
        
    done < <(find /dev -mindepth 1 -maxdepth 1 -print0) # /dev 하위 파일만 검사함. depth 1

    if [ ${#vuln_list[@]} -gt 0 ]; then
        local joined
        joined=$(IFS=','; echo "${vuln_list[*]}")
        result_fail "U-16 /dev에 유효하지 않은 파일 존재 (취약): $joined"
    else
        result_pass "U-16 /dev 하위 모든 장치 파일이 유효함 (양호)"
    fi
}

# U-17 $HOME/.rhosts, hosts.equiv 사용 금지
check_rhosts() {
    if should_skip "U-17"; then
        return
    fi

    log_check_start "U-17" "for .rhosts and hosts.equiv files"
    local rc

    # 1) /etc/hosts.equiv 먼저 검사
    if [ -f "/etc/hosts.equiv" ]; then
        # 소유자/권한 검사
        check_owner_perm "/etc/hosts.equiv" "root" 600
        rc=$?
        if [ $rc -eq 0 ]; then
            result_fail "U-17 /etc/hosts.equiv 파일의 소유자 또는 권한이 적절하지 않음 (취약)"
            return
        fi

        # + 포함 검사
        if grep -q '^[[:space:]]*\+' /etc/hosts.equiv 2>/dev/null; then
            result_fail "U-17 /etc/hosts.equiv 파일에 '+' 설정 (취약)"
            return
        fi
    fi

    # 2) 각 사용자 홈 디렉터리의 .rhosts 파일 검사
    while IFS=: read -r username _ uid _ _ home _; do
        if [[ "$uid" -ge 1000 && -d "$home" ]]; then
            if [ -f "$home/.rhosts" ]; then
                check_owner_perm "$home/.rhosts" "$username" 600
                rc=$?
                if [ $rc -eq 0 ]; then
                    result_fail "U-17 $home/.rhosts 파일의 소유자 또는 권한이 적절하지 않음 (취약)"
                    return
                fi

                if grep -q '^[[:space:]]*\+' $home/.rhosts 2>/dev/null; then
                    result_fail "U-17 $home/.rhosts 파일에 '+' 설정 (취약)"
                    return
                fi
            fi
        fi
    done < /etc/passwd

    result_pass "U-17 .rhosts 및 /etc/hosts.equiv 파일 양호 (양호)"
}

# U-18 접속 IP 포트 제한
check_ip_port_restriction() {
    if should_skip "U-18"; then
        return
    fi

    log_check_start "U-18" "for a connection IP / port restriction"

    # 1) TCP Wrapper 사용 여부 확인 (libwrap)
    local bin
    local services=(
        systat
        fingerd
        ftpd
        telnetd
        rlogind
        rshd
        talkd
        execd
        tftpd
        sshd
    )
    local used=false
    if command -v tcpd >/dev/null 2>&1; then
        used=true
    fi
    for svc in "${services[@]}"; do
        bin=$(command -v "$svc" 2>/dev/null) || continue
        if ldd "$bin" 2>/dev/null | grep -q libwrap; then
            used=true
            break
        fi
    done

    # 2) TCP Wrapper 사용하는 경우 설정 확인 (/etc/hosts.deny & /etc/hosts.allow)
    if $used; then
        if grep -qE '^\s*ALL:\s*ALL' /etc/hosts.deny 2>/dev/null && [ -s /etc/hosts.allow ]; then
            :
        else
            result_fail "U-18 TCP Wrapper 미설정: /etc/hosts.deny에 ALL: ALL 없거나 /etc/hosts.allow 파일 없음 " 
        fi
    fi

    # 3) iptables 기본 정책 확인
    if command -v iptables >/dev/null 2>&1; then
        local policy
        # 기본 INPUT 정책 뽑기
        policy=$(iptables -L INPUT -n | awk '/Chain INPUT/ {print $4}' | tr -d ')')
        if [ "$policy" != "DROP" ]; then
            result_fail "U-18 iptables: INPUT 체인 기본 정책이 $policy 으로 설정됨"
        fi
    fi

    result_pass "U-18 접속 IP/Port 제한 설정이 적절함 (양호)"
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
check_services_owner
check_env_file_owner
check_dev
check_rhosts
check_ip_port_restriction