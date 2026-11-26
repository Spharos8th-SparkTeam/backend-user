# user-service

ReSpark 회원 서비스다. 회원, 이메일 인증, 약관, 배송지, 정산 계좌, 프로필 카드, 신고, 월간 멤버십, 관리자 계정을 다룬다.

현재 단계는 API 정의서 기준의 껍데기다. 요청과 응답 스키마는 Swagger에 보이며, 데이터는 저장하지 않는다. 회원 원장 엔티티는 `member` 테이블에 매핑한다.

## 주요 기능

- `POST /api/v1/email/verifications`
- `POST /api/v1/auth/signup`, `/login`, `/social/signup`, `/social/login`, `/logout`, `/password/reset`, `PATCH /password`
- `GET`, `PATCH`, `DELETE /api/v1/users/{userId}`
- `POST`, `GET /api/v1/users/{userId}/address`, `/account`
- `GET /api/v1/terms`, `GET /api/v1/admin/{userId}`

## 기술 스택

- Java 21
- Spring Boot 4.0.10
- springdoc-openapi 3.2.0
- Gradle 9

## 서비스 구성

이 저장소는 `user-service` 하나다. 현재 API 경로는 정의서의 `/api/v1/email`, `/api/v1/auth`, `/api/v1/users`, `/api/v1/terms`, `/api/v1/admin`이다. 다른 서비스의 데이터베이스에는 접근하지 않는다.

결제 승인과 Kafka 발행·소비는 이 서비스에 없다.

## 디렉터리 구조

```text
src/main/java/com/spark/user/
├── common/
│   ├── config/
│   └── exception/
├── member/entity/
├── email/
├── auth/
├── user/
├── address/
├── account/
├── terms/
└── admin/
```

각 도메인은 `controller`, `service`, `dto/request`, `dto/response`로 나눈다.

## 실행 방법

로컬 Swagger 확인에는 환경변수가 필요 없다. 기본 포트는 8080이다.

```text
gradlew.bat bootRun
```

- Swagger UI: `http://localhost:8080/swagger-ui.html`
- OpenAPI: `http://localhost:8080/v3/api-docs`

포트를 바꾸려면 `SERVER_PORT`를 지정한다.

## 환경변수

DB, JWT, Eureka 값은 애플리케이션이 아직 읽지 않는다. 배포 워크플로는 Dev DB Secret `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`와 Prod DB Secret `DB_URL_PROD`, `DB_USERNAME_PROD`, `DB_PASSWORD_PROD`를 컨테이너에 넘긴다. Docker Hub와 Prod SSH는 Organization Secret `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `HOST_EC2`, `EC2_KEY`를 사용한다.

Secret 값은 이 문서와 소스에 적지 않는다.

## 배포

`develop`으로 머지하면 Dev, `main`으로 머지하면 Prod에 배포한다. 이미지는 `user-service`다. 절차는 `docs/cicd-log-guide.md`를 따른다.
