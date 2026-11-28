# ReSpark CI/CD 및 로그 확인 가이드

ReSpark 백엔드의 Docker 이미지 빌드, Docker Hub 업로드, Dev / Prod 배포, AWS 서버 로그 확인 방법을 정리한 공통 가이드다. 예제는 `member-service`이며, 각 담당자는 자신의 프로젝트 이름과 환경변수에 맞게 바꾼다.

이 문서에는 서버 주소, 접속 계정, 키 파일 경로, 비밀번호를 적지 않는다. 아래 플레이스홀더를 팀에서 별도로 관리하는 값으로 바꿔 사용한다.

| 플레이스홀더 | 의미 |
| --- | --- |
| `<PROD_HOST>` | Prod EC2 탄력적 IP. GitHub Secret `HOST_EC2`에 등록하는 값 |
| `<SSH_USER>` | EC2 SSH 접속 계정. 워크플로 `username`과 로컬 `ssh` 명령에 사용 |
| `<PEM_PATH>` | 로컬에 보관한 PEM 개인 키 파일 경로. 저장소에 커밋하지 않는다 |
| `<DB_HOST>` | MySQL 호스트. JDBC URL 예시용 |
| `<CONTAINER_NAME>` | `docker ps`의 `NAMES` 값. 예: `member-service`, `gateway`, `eureka` |

Secret의 실제 값은 GitHub Actions Secrets에만 둔다. 소스, 워크플로 YAML, 이 문서, 메신저에 평문으로 적지 않는다.

## 1. CI/CD 구성

```text
GitHub Repository (PR Merge)
        │
        ▼
GitHub Actions (Docker Build)
        │
        ▼
Docker Hub (이미지 Push)
        │
        ├─ develop 대상 Merge → Dev 서버
        └─ main 대상 Merge    → Prod 서버
```

| 구분 | Dev 서버 | Prod 서버 |
| --- | --- | --- |
| 서버 / OS | Windows | AWS EC2 / Ubuntu |
| 대상 브랜치 | `develop` | `main` |
| 배포 조건 | PR Merge | PR Merge |
| 배포 방식 | Self-hosted Runner | SSH |
| Spring Profile | `dev` | `prod` |
| Docker Network | `spharos` | `spharos` |

배포는 PR이 Merge된 경우에만 실행된다. 브랜치에 직접 Push하거나, PR을 만들기만 하거나, Merge 없이 PR을 닫으면 배포되지 않는다.

## 2. `gradle.yml` 작성

프로젝트 최상위에 `.github/workflows/gradle.yml`을 만든다. 파일이 있으면 기존 내용을 수정한다.

```text
member-service/
├── .github/workflows/gradle.yml
├── src/
├── build.gradle
├── settings.gradle
├── Dockerfile
├── gradlew
└── gradlew.bat
```

아래 YAML은 `member-service` 예제다. `member-service` 문자열, 작업 이름, 환경변수는 3장 기준으로 바꾼다. `username`의 `<SSH_USER>`는 복사 후 실제 SSH 계정으로 바꾸며, 그 값을 이 문서에는 남기지 않는다. Prod 접속 주소와 PEM 내용은 각각 `HOST_EC2`, `EC2_KEY` Secret으로 넘긴다. YAML에 IP나 키 파일 경로를 적지 않는다.

```yaml
name: Java CI with Gradle

on:
  # push:
  #   branches: [ "main" ]
  # pull_request:
  #   branches: [ "main" ]
  pull_request:
    types: [closed]
    branches: ["main", "develop"]

permissions:
  contents: read

jobs:
  CI-CD:
    # if: github.event_name == 'push'
    if: github.event.pull_request.merged == true
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.merge_commit_sha }}

      - name: docker build & docker hub push
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker build -t "${{ secrets.DOCKER_USERNAME }}/member-service:${{ github.run_number }}" .
          docker push "${{ secrets.DOCKER_USERNAME }}/member-service:${{ github.run_number }}"

  Deploy-Dev:
    needs: CI-CD
    # if: github.event_name == 'push'
    if: github.event.pull_request.base.ref == 'develop'
    runs-on: [self-hosted, Windows, X64]
    steps:
      - name: Login to Docker Hub
        uses: docker/login-action@v3
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Deploy to develop
        shell: powershell
        env:
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          IMAGE_TAG: ${{ github.run_number }}
          SPRING_DATASOURCE_URL: ${{ secrets.SPRING_DATASOURCE_URL }}
          SPRING_DATASOURCE_USERNAME: ${{ secrets.SPRING_DATASOURCE_USERNAME }}
          SPRING_DATASOURCE_PASSWORD: ${{ secrets.SPRING_DATASOURCE_PASSWORD }}
          KAFKA_BOOTSTRAP_SERVERS: ${{ secrets.KAFKA_BOOTSTRAP_SERVERS }}
        run: |
          $ErrorActionPreference = "Continue"
          $PSNativeCommandUseErrorActionPreference = $false
          $image = "$env:DOCKER_USERNAME/member-service:$env:IMAGE_TAG"
          docker pull $image
          if ($LASTEXITCODE -ne 0) { exit 1 }
          $network = @(
            docker network ls --format "{{.Name}}" |
            Where-Object { $_ -eq "spharos" }
          )
          if ($network.Count -eq 0) {
            docker network create spharos
            if ($LASTEXITCODE -ne 0) { exit 1 }
          }
          $container = @(
            docker ps -a --filter "name=member-service" --format "{{.Names}}" |
            Where-Object { $_ -eq "member-service" }
          )
          if ($container.Count -gt 0) {
            docker rm -f member-service
            if ($LASTEXITCODE -ne 0) { exit 1 }
          }
          docker run -d `
            --name member-service `
            --restart unless-stopped `
            --network spharos `
            -e SPRING_PROFILES_ACTIVE=dev `
            -e "SPRING_DATASOURCE_URL=$env:SPRING_DATASOURCE_URL" `
            -e "SPRING_DATASOURCE_USERNAME=$env:SPRING_DATASOURCE_USERNAME" `
            -e "SPRING_DATASOURCE_PASSWORD=$env:SPRING_DATASOURCE_PASSWORD" `
            -e "KAFKA_BOOTSTRAP_SERVERS=$env:KAFKA_BOOTSTRAP_SERVERS" `
            -e EUREKA_CLIENT_SERVICEURL_DEFAULTZONE=http://eureka:8761/eureka/ `
            -e EUREKA_INSTANCE_PREFER_IP_ADDRESS=true `
            $image
          if ($LASTEXITCODE -ne 0) { exit 1 }
          $running = docker inspect -f "{{.State.Running}}" member-service
          if ($LASTEXITCODE -ne 0 -or $running -ne "true") { exit 1 }

      - name: Check member-service Container
        shell: powershell
        run: |
          $ErrorActionPreference = "Continue"
          $PSNativeCommandUseErrorActionPreference = $false
          docker ps --filter "name=^/member-service$"
          if ($LASTEXITCODE -ne 0) { exit 1 }
          $running = docker inspect -f "{{.State.Running}}" member-service
          if ($LASTEXITCODE -ne 0 -or $running -ne "true") { exit 1 }

  Deploy-Prod:
    needs: CI-CD
    # if: github.ref_name == 'main'
    if: github.event.pull_request.base.ref == 'main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy Member Service to AWS
        uses: appleboy/ssh-action@v1.2.0
        env:
          DOCKER_USERNAME: ${{ secrets.DOCKER_USERNAME }}
          DOCKER_PASSWORD: ${{ secrets.DOCKER_PASSWORD }}
          IMAGE_TAG: ${{ github.run_number }}
          SPRING_DATASOURCE_URL: ${{ secrets.DB_URL_PROD }}
          SPRING_DATASOURCE_USERNAME: ${{ secrets.DB_USERNAME_PROD }}
          SPRING_DATASOURCE_PASSWORD: ${{ secrets.DB_PASSWORD_PROD }}
        with:
          host: ${{ secrets.HOST_EC2 }}
          username: ubuntu
          key: ${{ secrets.EC2_KEY }}
          port: 22
          envs: DOCKER_USERNAME,DOCKER_PASSWORD,IMAGE_TAG,SPRING_DATASOURCE_URL,SPRING_DATASOURCE_USERNAME,SPRING_DATASOURCE_PASSWORD
          script: |
            set -eu
            IMAGE="$DOCKER_USERNAME/member-service:$IMAGE_TAG"
            : "${SPRING_DATASOURCE_URL:?DB URL missing}"
            : "${SPRING_DATASOURCE_USERNAME:?DB username missing}"
            : "${SPRING_DATASOURCE_PASSWORD:?DB password missing}"
            echo "$DOCKER_PASSWORD" | docker login \
              -u "$DOCKER_USERNAME" \
              --password-stdin
            docker pull "$IMAGE"
            docker network inspect spharos >/dev/null 2>&1 \
              || docker network create spharos
            docker rm -f member-service 2>/dev/null || true
            docker run -d \
              --name member-service \
              --restart unless-stopped \
              --network spharos \
              -e SPRING_DATASOURCE_URL \
              -e SPRING_DATASOURCE_USERNAME \
              -e SPRING_DATASOURCE_PASSWORD \
              -e SPRING_PROFILES_ACTIVE=prod \
              "$IMAGE"
            test "$(docker inspect -f '{{.State.Running}}' member-service)" = true
            docker ps --filter "name=^/member-service$"
            docker logs --tail 50 member-service
```

`CI-CD` Job이 이미지를 만든 뒤, PR 대상 브랜치에 따라 `Deploy-Dev` 또는 `Deploy-Prod` 중 하나만 실행된다.

## 3. 프로젝트별 적용

### 3-1. 프로젝트 이름

`gradle.yml`의 `member-service`를 담당 프로젝트 이름으로 모두 바꾼다. Docker 이미지 이름, 컨테이너 이름, 상태 확인 명령, 작업 이름(`Deploy Member Service to AWS` 등)에 같은 이름을 쓴다.

| 기존 | 변경 예시 |
| --- | --- |
| `member-service` | `product-service` |
| `member-service` | `payment-service` |
| `member-service` | `purchase-service` |
| `member-service` | `chat-service` |
| `member-service` | `settlement-service` |

### 3-2. GitHub Actions Secrets

Secret 이름은 `gradle.yml`의 참조 이름과 같아야 한다. Dev DB와 Prod DB 값을 서로 바꾸어 등록하지 않는다.

#### 공통 시크릿 (Organization)

팀장이 관리한다. 각 Repository에 같은 키를 다시 만들 필요는 없고, 해당 Repository에 사용 권한이 있어야 한다.

| Secret | 설명 |
| --- | --- |
| `HOST_EC2` | Prod EC2 탄력적 IP (`<PROD_HOST>`) |
| `EC2_KEY` | SSH용 PEM 개인 키 내용. 파일 경로(`<PEM_PATH>`)가 아니다 |
| `DOCKER_USERNAME` | 공용 Docker Hub 계정명 |
| `DOCKER_PASSWORD` | 공용 Docker Hub Access Token |

#### Dev 서버 시크릿 (Repository)

| Secret | 설명 |
| --- | --- |
| `SPRING_DATASOURCE_URL` | Dev MySQL 접속 URL |
| `SPRING_DATASOURCE_USERNAME` | Dev DB 사용자명 |
| `SPRING_DATASOURCE_PASSWORD` | Dev DB 비밀번호 |

#### Prod 서버 시크릿 (Repository)

워크플로는 Prod Secret을 컨테이너 환경변수 `SPRING_DATASOURCE_*`로 넘긴다.

| Secret | 설명 |
| --- | --- |
| `DB_URL_PROD` | Prod MySQL 접속 URL |
| `DB_USERNAME_PROD` | Prod DB 사용자명 |
| `DB_PASSWORD_PROD` | Prod DB 비밀번호 |

#### 기타 시크릿

| Secret | 설명 |
| --- | --- |
| `KAFKA_BOOTSTRAP_SERVERS` | Dev Kafka 브로커 접속 정보 |

Kafka, MongoDB, Redis, JWT, 외부 API처럼 서비스에 필요한 값은 담당자가 Secret으로 추가한다. 쓰지 않는 항목은 `env`, `envs`, `docker run -e`에서 뺀다. 예제에서 Kafka와 Eureka 설정은 Dev Job에만 있다. Prod에서도 필요하면 같은 방식으로 `env`, `envs`, `script`의 `docker run -e`에 넣는다.

### 3-3. Repository Secret 등록

Repository → Settings → Secrets and variables → Actions → New repository secret → Name과 Secret 입력 → Add secret.

### 3-4. DB 스키마

| 프로젝트 | 스키마 이름 예시 |
| --- | --- |
| `member-service` | `member_db` |
| `product-service` | `product_db` |
| `payment-service` | `payment_db` |
| `purchase-service` | `purchase_db` |
| `settlement-service` | `settlement_db` |

JDBC URL 예시는 `jdbc:mysql://<DB_HOST>:3306/member_db`다. `<DB_HOST>`와 스키마 이름은 팀이 지정한 값으로 바꾼다. Dev와 Prod 각각 스키마가 있고, DB 사용자에게 접근 권한이 있는지 확인한다.

## 4. 신규 Repository의 공통 시크릿 권한

Organization에 등록된 공통 시크릿을 새 Repository에서 쓰려면 팀장이 접근 목록에 추가한다.

1. `Spharos8th-SparkTeam` Organization의 Settings로 이동한다.
2. Secrets and variables → Actions를 연다.
3. `HOST_EC2`를 선택하고 Edit를 누른다.
4. Repository access의 Selected repositories에 신규 Repository를 추가하고 저장한다.

Spark 팀은 Selected repositories를 사용한다. 선택된 Repository만 해당 키를 쓸 수 있다. `HOST_EC2`, `EC2_KEY`, `DOCKER_USERNAME`, `DOCKER_PASSWORD` 네 키에 같은 접근 범위를 적용한다. Organization 키 접근이 확인되면, Repository에 중복 등록한 같은 이름의 키는 삭제해도 된다.

## 5. 실행과 결과 확인

### 5-1. 실행 조건

```yaml
on:
  pull_request:
    types: [closed]
    branches: ["main", "develop"]

jobs:
  CI-CD:
    if: github.event.pull_request.merged == true
```

| Git 작업 | 배포 |
| --- | --- |
| `feature` / `develop` / `main`에 직접 Push | 배포하지 않음 |
| PR 생성 또는 승인 | 배포하지 않음 |
| `develop` 대상 PR Merge | Dev 서버 배포 |
| `main` 대상 PR Merge | Prod 서버 배포 |
| Merge 없이 PR Close | Job 건너뜀 (Skipped) |

배포 순서는 다음과 같다.

1. `feature` 브랜치에서 기능 개발을 마친다.
2. `develop`으로 PR을 요청하고 승인한 뒤 Merge한다.
3. Dev 서버에서 기능과 API를 확인한다.
4. `main`으로 PR을 요청하고 승인한 뒤 Merge한다.
5. Prod 서버에서 운영 환경을 확인한다.

두 배포 Job은 `CI-CD`가 성공한 뒤에 실행되며, PR 대상 브랜치에 따라 하나만 실행된다. Dev 테스트 성공을 워크플로가 자동으로 강제하지는 않는다.

### 5-2. Actions 결과

Repository의 Actions 탭에서 실행 결과를 확인한다.

| Job | `develop` PR Merge | `main` PR Merge |
| --- | --- | --- |
| `CI-CD` | Success | Success |
| `Deploy-Dev` | Success | Skipped |
| `Deploy-Prod` | Skipped | Success |

| 상태 | 의미 |
| --- | --- |
| Success | 작업 성공 |
| Failure | 작업 실패. 해당 Step 로그를 확인한다 |
| In progress | 작업 진행 중 |
| Skipped | 실행 조건에 해당하지 않음 |
| Queued | Runner 할당 대기 |

대상 브랜치 때문에 배포 Job 하나가 Skipped인 것은 정상이다. 실패한 Job을 열어 오류가 난 Step 로그를 확인한다.

### 5-3. 배포 후 서버 확인

Actions 성공만으로 애플리케이션 기동이 보장되지는 않는다. 컨테이너 상태, 애플리케이션 로그, Eureka 등록, Gateway를 통한 API 호출을 함께 확인한다.

Dev(Windows Runner)에서는 `docker`를 쓰고, Prod(Ubuntu)에 SSH로 들어가 수동 확인할 때는 `sudo docker`를 쓴다. 컨테이너 이름은 프로젝트 이름으로 바꾼다.

| 확인 | Dev (Windows) | Prod (Ubuntu, SSH 접속 후) |
| --- | --- | --- |
| 실행 중인 컨테이너 | `docker ps` | `sudo docker ps` |
| 종료된 컨테이너 포함 | `docker ps -a` | `sudo docker ps -a` |
| 최근 로그 | `docker logs --tail 100 member-service` | `sudo docker logs --tail 100 --timestamps member-service` |
| 실시간 로그 | `docker logs -f member-service` | `sudo docker logs -f --tail 50 member-service` |

실시간 로그는 `Ctrl + C`로 종료한다. 컨테이너는 멈추지 않는다.

## 6. AWS SSH 접속 및 Docker 로그

Windows CMD에서 Prod EC2(Ubuntu)에 접속해 컨테이너 상태와 서비스 로그를 조회한다. 인스턴스마다 탄력적 IP, PEM 키, 컨테이너 목록이 다를 수 있다.

- 서비스 인스턴스: Eureka, Gateway, Spring 서비스
- 인프라 인스턴스: MySQL, Redis, Kafka, 모니터링

### 6-1. 접속 전 준비

1. 대상 EC2 인스턴스가 실행 중인지 확인한다.
2. 해당 인스턴스의 탄력적 IP(`<PROD_HOST>`)와 PEM 키 파일(`<PEM_PATH>`)을 준비한다.
3. PEM 파일은 저장소 밖에 두고, 권한이 넓은 상태로 두지 않는다.

### 6-2. Windows CMD에서 접속

SSH 명령은 Windows CMD에서 실행한다. 접속 이후 Docker 명령은 Ubuntu 서버에서 실행한다.

1. 파일 탐색기에서 PEM 키가 있는 폴더를 연다.
2. 주소창에 `cmd`를 입력하고 Enter를 눌러 그 폴더에서 CMD를 연다.
3. 아래 명령을 실행한다. 따옴표 안의 경로는 실제 키 파일 경로로 바꾼다.

```text
ssh -i "<PEM_PATH>" <SSH_USER>@<PROD_HOST>
```

4. 최초 접속 시 호스트 지문 확인이 나오면, 서버 담당자와 지문을 맞춘 뒤 `yes`를 입력한다.
5. `<SSH_USER>@...` 프롬프트가 보이면 접속된 것이다.

### 6-3. 컨테이너 상태

컨테이너 이름은 `NAMES` 열에서 확인한 뒤 로그 명령에 넣는다.

```text
sudo docker ps
sudo docker ps -a
```

| 항목 | 의미 |
| --- | --- |
| `NAMES` | 컨테이너 이름. 로그 명령에 이 이름을 쓴다 |
| `STATUS` | `Up`(실행 중), `Exited`(종료), `Restarting`(재시작 중) |
| `PORTS` | 포트 매핑 |

### 6-4. 서비스 로그

`<CONTAINER_NAME>`은 `sudo docker ps` 결과의 이름으로 바꾼다.

```text
sudo docker logs --tail 100 --timestamps <CONTAINER_NAME>
sudo docker logs --since 30m --timestamps <CONTAINER_NAME>
sudo docker logs -f --tail 50 <CONTAINER_NAME>
```

예시:

```text
sudo docker logs --tail 100 --timestamps gateway
sudo docker logs -f --tail 50 eureka
```

실시간 추적은 `Ctrl + C`로 끝낸다. 로그만 멈추고 컨테이너는 계속 실행된다.

오류를 볼 때는 `ERROR`, `Exception`, `Failed`와 그 직전 로그를 같이 본다. 컨테이너가 `Up`이어도 애플리케이션이 정상 기동된 것은 아니므로, Eureka 등록과 Gateway API 호출을 이어서 확인한다.

### 6-5. 접속 종료

```text
exit
```

`Ctrl + D`로도 SSH를 끊고 Windows CMD로 돌아온다.

## 7. 주요 오류

| 증상 | 확인할 것 |
| --- | --- |
| Docker login unauthorized | Docker Hub 계정과 Access Token (`DOCKER_USERNAME`, `DOCKER_PASSWORD`) |
| `Permission denied (publickey)` | `EC2_KEY`, `HOST_EC2`(`<PROD_HOST>`), 접속 계정(`<SSH_USER>`), 서버에 등록된 공개 키 |
| SSH connection timeout / `Connection timed out` | EC2 실행 여부, 탄력적 IP, 네트워크. 필요하면 서버 담당자에게 SSH 접근 설정을 문의한다 |
| `UNPROTECTED PRIVATE KEY FILE` | 로컬 PEM(`<PEM_PATH>`)의 Windows 접근 권한이 너무 넓다. 서버 담당자에게 권한 조정을 요청한다 |
| `DB URL missing` | `DB_URL_PROD` 등록 여부 |
| `Access denied for user` | DB 사용자명, 비밀번호, 접근 권한. Dev / Prod Secret을 구분한다 |
| `Unknown database` | 프로젝트 DB 스키마 생성 여부 |
| Network not found | `spharos` Docker Network |
| Container name conflict | 기존 컨테이너 상태. 배포 스크립트는 같은 이름 컨테이너를 제거한 뒤 다시 실행한다 |
| Runner 대기(Queued)가 계속됨 | Dev 서버와 Self-hosted Runner 실행 여부 |
| 컨테이너가 실행 직후 종료 | `docker logs`의 Spring Boot 기동 오류와 환경변수 |
| `No such container` | `sudo docker ps -a`로 실제 컨테이너 이름을 다시 확인한다 |
| Docker `permission denied` | Ubuntu에서 `sudo docker ...`로 실행했는지 확인한다 |
| PR Merge 후 배포되지 않음 | 대상 브랜치(`develop` / `main`)와 workflow의 `on`, `if` |
| 공통 시크릿을 인식하지 못함 | Organization의 Selected repositories에 해당 Repository가 있는지 |

## 8. 적용 체크리스트

### 프로젝트

- [ ] `Dockerfile` 생성 및 확인
- [ ] `.github/workflows/gradle.yml` 생성
- [ ] `member-service`를 담당 프로젝트 이름으로 변경
- [ ] 워크플로의 `<SSH_USER>`를 실제 SSH 계정으로 변경하고, 계정·IP·키 경로를 문서와 소스에 남기지 않음
- [ ] `application-dev.yml`, `application-prod.yml` 확인

### DB와 Secret

- [ ] Dev DB 스키마와 접근 권한 확인
- [ ] Prod DB 스키마와 접근 권한 확인
- [ ] Repository 개별 Secret 등록
- [ ] Organization 공통 Secret 4개(`HOST_EC2`, `EC2_KEY`, `DOCKER_USERNAME`, `DOCKER_PASSWORD`) 접근 권한 확인
- [ ] 프로젝트에 필요한 환경변수를 `env`, `envs`, `docker run -e`에 반영

### Dev 배포

- [ ] `develop` 대상 PR Merge
- [ ] GitHub Actions 결과 확인 (`CI-CD`, `Deploy-Dev` Success, `Deploy-Prod` Skipped)
- [ ] Dev 컨테이너와 로그 확인
- [ ] Eureka 등록 확인
- [ ] Gateway를 통한 API 호출 확인

### Prod 배포

- [ ] `main` 대상 PR Merge
- [ ] GitHub Actions 결과 확인 (`CI-CD`, `Deploy-Prod` Success, `Deploy-Dev` Skipped)
- [ ] `ssh -i "<PEM_PATH>" <SSH_USER>@<PROD_HOST>` 로 접속
- [ ] `sudo docker ps`와 `sudo docker logs`로 컨테이너·로그 확인
- [ ] Eureka 등록 확인
- [ ] Gateway를 통한 API 호출 확인
