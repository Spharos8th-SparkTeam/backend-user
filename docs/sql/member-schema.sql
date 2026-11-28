-- user-service schema extracted from docs/ReSpark.sql
-- member 원장 10개, member_query.profile_card, terms_document 초기 데이터.
-- 스키마 안팎 모두 외래키 없이 CHAR(36) UUID 값만 가리킨다.
SET NAMES utf8mb4;
-- -----------------------------------------------------
-- Schema member
-- 회원, 인증, 약관, 배송지, 정산 계좌.
-- 스키마 안팎 모두 외래키 없이 CHAR(36) UUID 값만 가리킨다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS member
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE member;

CREATE TABLE member (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  email VARCHAR(254) NOT NULL,
  nickname VARCHAR(30) NOT NULL,
  profile_image_key VARCHAR(255) NULL,
  preferred_language VARCHAR(8) NOT NULL DEFAULT 'ko',
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  email_verified_at DATETIME(6) NULL,
  suspended_until DATETIME(6) NULL,
  withdrawn_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_member_uuid (member_uuid),
  UNIQUE KEY uk_member_email (email),
  UNIQUE KEY uk_member_nickname (nickname),
  KEY ix_member_status (status, created_at),
  CONSTRAINT ck_member_status CHECK (status IN ('ACTIVE', 'SUSPENDED', 'WITHDRAWN')),
  CONSTRAINT ck_member_language CHECK (preferred_language IN ('ko', 'en', 'ja', 'zh-CN', 'zh-TW'))
) COMMENT='구매자이자 판매자인 회원 원장';

CREATE TABLE member_credential (
  member_uuid CHAR(36) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  password_changed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (member_uuid)
) COMMENT='이메일 가입 비밀번호. 소셜 전용 회원은 행이 없다';

CREATE TABLE member_social_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  provider VARCHAR(20) NOT NULL,
  provider_user_id VARCHAR(255) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_social_provider_user (provider, provider_user_id),
  KEY ix_social_member (member_uuid),
  CONSTRAINT ck_social_provider CHECK (provider IN ('LINE', 'GOOGLE', 'X', 'APPLE'))
) COMMENT='소셜 식별자. 한 회원이 여러 공급자를 가질 수 있다';

CREATE TABLE shipping_address (
  id BIGINT NOT NULL AUTO_INCREMENT,
  address_uuid CHAR(36) NOT NULL,
  member_uuid CHAR(36) NOT NULL,
  recipient_name VARCHAR(100) NOT NULL,
  phone_number VARCHAR(30) NOT NULL,
  address_line VARCHAR(255) NOT NULL,
  address_detail VARCHAR(150) NOT NULL,
  postcode VARCHAR(20) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  deleted_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  default_marker CHAR(36)
    GENERATED ALWAYS AS (CASE WHEN is_default = 1 AND deleted_at IS NULL THEN member_uuid ELSE NULL END) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uk_address_uuid (address_uuid),
  UNIQUE KEY uk_address_one_default (default_marker),
  KEY ix_address_member (member_uuid, deleted_at)
) COMMENT='회원 배송지. 기본 배송지는 회원당 하나이며 삭제를 막는다';

CREATE TABLE payout_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  account_uuid CHAR(36) NOT NULL,
  member_uuid CHAR(36) NOT NULL,
  holder_name VARCHAR(100) NOT NULL,
  bank_name VARCHAR(100) NOT NULL,
  bank_code VARCHAR(20) NOT NULL,
  account_number_cipher VARCHAR(512) NOT NULL,
  encryption_key_id VARCHAR(64) NOT NULL,
  is_default TINYINT(1) NOT NULL DEFAULT 0,
  deleted_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  default_marker CHAR(36)
    GENERATED ALWAYS AS (CASE WHEN is_default = 1 AND deleted_at IS NULL THEN member_uuid ELSE NULL END) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uk_account_uuid (account_uuid),
  UNIQUE KEY uk_account_one_default (default_marker),
  KEY ix_account_member (member_uuid, deleted_at)
) COMMENT='정산 계좌. 계좌번호는 암호문만 저장한다';

CREATE TABLE terms_document (
  id BIGINT NOT NULL AUTO_INCREMENT,
  terms_uuid CHAR(36) NOT NULL,
  terms_code VARCHAR(40) NOT NULL,
  version_label VARCHAR(40) NOT NULL,
  title VARCHAR(200) NOT NULL,
  content_url VARCHAR(500) NOT NULL,
  required_flag TINYINT(1) NOT NULL DEFAULT 1,
  effective_at DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_terms_uuid (terms_uuid),
  UNIQUE KEY uk_terms_code_version (terms_code, version_label)
) COMMENT='약관 기준정보. 본문은 HTML 파일이고 여기에는 주소만 둔다';

CREATE TABLE member_terms_agreement (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  terms_uuid CHAR(36) NOT NULL,
  terms_version VARCHAR(40) NOT NULL,
  agreed TINYINT(1) NOT NULL,
  agreed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_agreement_once (member_uuid, terms_uuid),
  KEY ix_agreement_terms (terms_uuid)
) COMMENT='회원가입과 마케팅 수신 동의 기록';

CREATE TABLE email_challenge (
  id BIGINT NOT NULL AUTO_INCREMENT,
  email VARCHAR(254) NOT NULL,
  purpose VARCHAR(32) NOT NULL,
  code_hash VARCHAR(100) NOT NULL,
  member_uuid CHAR(36) NULL,
  expires_at DATETIME(6) NOT NULL,
  consumed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_challenge_email (email, purpose, expires_at),
  KEY ix_challenge_member (member_uuid),
  CONSTRAINT ck_challenge_purpose CHECK (purpose IN ('SIGNUP', 'PASSWORD_RESET', 'PASSWORD_CHANGE', 'WITHDRAW'))
) COMMENT='인증번호. 회원 행이 생기기 전에도 쓰이며 member_uuid 만 담는다';

CREATE TABLE login_history (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  login_ip VARCHAR(45) NOT NULL,
  client_os VARCHAR(40) NOT NULL,
  logged_in_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_login_member (member_uuid, logged_in_at)
) COMMENT='로그인 이력. 관리자 화면의 IP와 OS 원장';

CREATE TABLE withdrawal_vault (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  payload_cipher TEXT NOT NULL,
  encryption_key_id VARCHAR(64) NOT NULL,
  has_trade TINYINT(1) NOT NULL,
  retain_until DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_vault_member (member_uuid),
  KEY ix_vault_retain (retain_until)
) COMMENT='거래가 있는 탈퇴 회원의 이메일, 계좌, 주소 암호문. 5년 보관';

INSERT INTO terms_document (terms_uuid, terms_code, version_label, title, content_url, required_flag, effective_at) VALUES
  ('a1000001-0000-4000-8000-000000000001', 'SERVICE', '2026-01', '서비스 이용약관', 'https://cdn.respark.local/terms/service-2026-01.html', 1, '2026-01-01 00:00:00.000000'),
  ('a1000001-0000-4000-8000-000000000002', 'PRIVACY', '2026-01', '개인정보 수집 및 이용', 'https://cdn.respark.local/terms/privacy-2026-01.html', 1, '2026-01-01 00:00:00.000000'),
  ('a1000001-0000-4000-8000-000000000003', 'PAYMENT', '2026-01', '안전결제 이용약관', 'https://cdn.respark.local/terms/payment-2026-01.html', 1, '2026-01-01 00:00:00.000000'),
  ('a1000001-0000-4000-8000-000000000004', 'MARKETING', '2026-01', '마케팅 목적 개인정보 수집 및 이용', 'https://cdn.respark.local/terms/marketing-2026-01.html', 0, '2026-01-01 00:00:00.000000');

-- -----------------------------------------------------
-- Schema member_query
-- 프로필, 관리자 회원 목록이 읽는 카드. 회원과 멤버십 상품은 UUID 값만 담는다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS member_query
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE member_query;

CREATE TABLE profile_card (
  member_uuid CHAR(36) NOT NULL,
  email VARCHAR(254) NOT NULL,
  nickname VARCHAR(30) NOT NULL,
  profile_image_key VARCHAR(255) NULL,
  status VARCHAR(20) NOT NULL,
  rating_avg DECIMAL(3,2) NOT NULL DEFAULT 0.00,
  review_count INT NOT NULL DEFAULT 0,
  trade_count INT NOT NULL DEFAULT 0,
  accepted_report_count INT NOT NULL DEFAULT 0,
  membership_active TINYINT(1) NOT NULL DEFAULT 0,
  membership_plan_uuid CHAR(36) NULL,
  next_billing_at DATETIME(6) NULL,
  last_login_at DATETIME(6) NULL,
  last_login_ip VARCHAR(45) NULL,
  last_login_os VARCHAR(40) NULL,
  suspended_until DATETIME(6) NULL,
  joined_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (member_uuid),
  UNIQUE KEY uk_profile_email (email),
  UNIQUE KEY uk_profile_nickname (nickname),
  KEY ix_profile_status (status, joined_at),
  KEY ix_profile_membership (membership_active, joined_at),
  KEY ix_profile_plan (membership_plan_uuid),
  CONSTRAINT ck_profile_rating CHECK (rating_avg >= 0 AND rating_avg <= 5),
  CONSTRAINT ck_profile_counts CHECK (review_count >= 0 AND trade_count >= 0 AND accepted_report_count >= 0)
) COMMENT='상점 프로필과 관리자 회원 목록의 조회 모델';
