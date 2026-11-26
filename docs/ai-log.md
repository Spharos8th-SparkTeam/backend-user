# AI 작업 로그

## 2026-11-26

- 기준 DB는 `docs/ReSpark.sql`이다. 회원, 인증, 약관, 배송지, 계좌, 프로필 카드, 신고/제재, 멤버십, 관리자 스키마를 현재 기준으로 둔다.
- 팀 룰, `docs/backend-config`, 회원 서비스 룰(`.cursor/rules/member-service.mdc`) 세팅을 마쳤다.
- 다음 단계는 새 레포에 `.cursor`, `.github`, `docs`, `.gitignore`를 세팅하고 push한 뒤, 1차 API 껍데기와 DTO 작업이다.

### 워크플로 검수와 Swagger 껍데기

- `docs/backend-config/src`는 예외 응답 필드와 패키지 형태만 참고했다. `core` 패키지와 기존 ErrorCode 번호는 가져오지 않았다.
- `.github/workflows/gradle.yml`의 트리거와 `CI-CD`, `Deploy-Dev`, `Deploy-Prod` 구조는 유지했다. 배포 Job 조건에 merge 성공과 `CI-CD` 성공을 함께 넣어, 머지되지 않은 PR close나 이미지 빌드 실패 때 배포가 나가지 않게 했다.
- 루트에 Dockerfile, Gradle 빌드 파일이 없어 `docker build`가 실패하는 상태였다. `user-service`용 Gradle 프로젝트, wrapper, Dockerfile을 추가했다.
- Prod Eureka 환경변수는 가이드 예제가 Dev에만 두고 있어 추가하지 않았다. 필요 여부는 확인이 남아 있다.
- 저장소 Secret 이름은 `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`, `DB_URL_PROD`, `DB_USERNAME_PROD`, `DB_PASSWORD_PROD`와 워크플로가 일치한다. `DOCKER_USERNAME`, `DOCKER_PASSWORD`, `HOST_EC2`, `EC2_KEY`는 가이드상 Organization Secret이라 이 저장소 목록에는 없었다.
- `member-service.mdc`에 실행 이름 `user-service`, 패키지 `com.spark.user`, API 접두사 `/api/v1/members`, `ErrorResponseDto`와 `common.exception`, DTO 접미사, Kafka Secret 제외, Prod Eureka 보류를 반영했다.
- Swagger 껍데기는 저장 없이 기동한다. 로컬 `http://localhost:8080/swagger-ui/index.html`에서 회원, 이메일 인증, 약관, 배송지, 정산 계좌, 프로필 카드, 신고, 멤버십, 관리자 목록을 확인했다. 회원 가입 껍데기는 201이며 응답에 비밀번호가 없다. `./gradlew test`는 통과했다.
- `prod` 프로필에서는 Swagger UI와 API docs를 끈다. 애플리케이션은 아직 DB와 Eureka를 읽지 않는다.

### API 정의서 기준으로 껍데기 재정리

- Swagger 경로를 정의서에 맞췄다. `POST /api/v1/email/verifications`, `POST /api/v1/auth/signup|login|social/signup|social/login|logout|password/reset`, `PATCH /api/v1/auth/password`, `GET|PATCH|DELETE /api/v1/users/{userId}`, `POST|GET /api/v1/users/{userId}/address|account`, `GET /api/v1/terms`, `GET /api/v1/admin/{userId}`.
- 정의서에 없던 신고, 멤버십, 프로필 카드 컨트롤러는 제거했다. 주석으로 남기지 않았다.
- `Member` 엔티티는 `@Table(name = "member")`다. Long PK 필드 `memberId`는 컬럼 `id`에 매핑하고, API `userId`는 `member_uuid`다.
- 로그인 응답에는 JWT를 넣지 않았다. 비밀번호, 인증번호, 계좌번호도 응답 스키마에 없다.
- JPA 의존성은 추가했고, DB 없이 기동되도록 데이터소스와 Hibernate 자동 설정은 빼 두었다. `./gradlew test`는 통과했다. 테스트는 OpenAPI 경로가 정의서와 같은지 확인한다.

### 남은 확인

- 팀 Gateway 예시 경로는 `/api/v1/members/**`다. 현재 컨트롤러는 정의서 경로를 쓴다. Gateway 라우팅을 정의서에 맞출지 확인이 필요하다.
- Prod에 `EUREKA_CLIENT_SERVICEURL_DEFAULTZONE`, `EUREKA_INSTANCE_PREFER_IP_ADDRESS`를 Dev와 같이 넣을지.
- Organization Secret 네 개가 이 저장소에 허용됐는지.
- 공통 성공 본문과 Validation 오류 형식은 아직 정하지 않았다. 잘못된 본문은 현재 Spring 기본 400이다.
- 껍데기 API는 저장하지 않는다. 요청 본문 필드가 정의서 원문과 다르면 원문 기준으로 고친다.
- 커밋과 푸시는 하지 않았다.

## 2026-11-27

- `member` 스키마 기준으로 회원 API 요청·응답을 확정했다. 경로와 HTTP 메서드는 유지하고, 응답은 리소스 본문만 둔다. 공통 성공 래퍼와 시각 문자열 형식은 아직 정하지 않았다.
- 소셜 로그인은 `provider`, `providerUserId`다. 목록 조회(배송지, 계좌, 약관)는 배열이다. 이메일 인증은 발송(201)과 확인(200)을 나누고, 확인 요청에만 인증번호 필드를 둔다. 응답에는 인증번호, 해시, 계좌번호, 암호문, 암호화 키, JWT, Long `id`를 넣지 않는다.
- 가입 요청에 약관 동의 배열을 넣었다. 가입·로그인 응답은 공통 프로필(`userId`, `email`, `nickname`, `profileImageKey`, `preferredLanguage`, `status`, `emailVerifiedAt`)이다. 관리자 회원 조회는 회원 상세이며 `loginId`, `roleCode`는 빼 두었다.
- 컨트롤러와 Request/Response DTO를 위 기준에 맞췄다. `AdminAccountResponseDto`의 식별자 필드가 `userId`로 바뀌어 `AdminAccountService` 빌더 호출 한 줄을 같이 고쳤다. 정의서 CSV는 수정하지 않았다.
- `./gradlew test`는 통과했다. 껍데기는 저장하지 않는다.
