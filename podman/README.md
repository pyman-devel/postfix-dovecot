
# Rootless Podman Pod 구성 가이드 (CentOS Stream 9 / RHEL 9 계열)

이 문서는 CentOS Stream 9 또는 RHEL 9 계열 시스템에서 Podman을 설치하고, 일반 사용자(rootless) 환경에서 Podman Pod를 구성하여 systemd 서비스처럼 운영하는 방법을 설명합니다.

---

## 1. Podman 및 관련 패키지 설치

```bash
dnf -y install podman systemd-container
```

- podman: Docker 호환 컨테이너 엔진  
- systemd-container: machinectl과 nspawn 기능 제공. rootless 서비스와 연동할 때 필요

---

## 2. 일반 사용자 생성 및 패스워드 제거

```bash
useradd -m pod_user
passwd -d pod_user
```

- `-m`: 홈 디렉토리 생성  
- `passwd -d`: 로그인 시 비밀번호 요구 제거 (보안이 필요한 경우 SSH 키 인증 권장)

---

## 3. 커널 파라미터 설정

```bash
vi /etc/sysctl.conf
```

다음 내용 추가:

```conf
user.max_user_namespaces = 1
net.ipv4.ip_unprivileged_port_start = 0
```

변경 적용:

```bash
sysctl -p
```

- user.max_user_namespaces: 사용자당 user namespace 수 제한  
- net.ipv4.ip_unprivileged_port_start: 일반 사용자도 1024 이하 포트 사용 가능

---

## 4. 로그인 유지 설정 (Linger)

```bash
loginctl enable-linger pod_user
```

- 해당 사용자의 systemd 인스턴스를 로그아웃 이후에도 백그라운드에서 유지 가능

---

## 5. 사용자 환경 진입

```bash
machinectl shell pod_user@
```

- pod_user@는 rootless 사용자 세션을 의미  
- machinectl은 컨테이너처럼 고립된 사용자 네임스페이스 제공

---

## 6. Podman Pod 생성 스크립트 준비

### 작업 디렉토리 생성 및 스크립트 작성

```bash
vi rootless_pod.sh
#!/bin/bash

HOSTNAME_VAR=$(hostname)

podman pod create \
  --name rootless_pod \
  --hostname $HOSTNAME_VAR \
  --security-opt no-new-privileges \
  -p 25:25 \
  -p 110:110 \
  -p 143:143 \
  -p 995:995 \
  -p 993:993 \
  -p 587:587 \
  -p 2424:2424 \
  -p 12345:12345 \
  -p 6379:6379 \
  -p 8888:8888 \
  -p 11332:11332 \
  -p 11334:11334 \
  -p 3306:3306
```
- --name: Pod 이름 지정  
- --hostname: Pod 내부 호스트 이름  
- --security-opt no-new-privileges: 권한 상승 방지  
- -p: 호스트 포트를 컨테이너로 포워딩

### 실행 권한 부여 및 실행

```bash
chmod +x rootless_pod.sh
./rootless_pod.sh
```

---

## 7. systemd 등록

```bash
podman generate systemd --name rootless_pod --files --new
mkdir -p ~/.config/systemd/user
cp pod-rootless_pod.service ~/.config/systemd/user/
cd ~/.config/systemd/user/
systemctl --user daemon-reexec
systemctl --user daemon-reload
systemctl --user enable --now pod-rootless_pod.service
systemctl --user status pod-rootless_pod.service
```

---
