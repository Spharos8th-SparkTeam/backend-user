-- ReSpark forward-engineer script
-- MySQL Workbench: File > Import > Reverse Engineer MySQL Create Script
-- 라이브 서버: Database > Reverse Engineer
-- Host 127.0.0.1  Port 3307  User root  Password respark_root
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
-- Schema backoffice
-- 관리자 계정. 회원 행과 제약으로 묶지 않고 UUID 도 공유하지 않는다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS backoffice
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE backoffice;

CREATE TABLE admin_account (
  id BIGINT NOT NULL AUTO_INCREMENT,
  admin_uuid CHAR(36) NOT NULL,
  login_id VARCHAR(50) NOT NULL,
  email VARCHAR(254) NOT NULL,
  password_hash VARCHAR(100) NOT NULL,
  role_code VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
  suspended_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_admin_uuid (admin_uuid),
  UNIQUE KEY uk_admin_login (login_id),
  UNIQUE KEY uk_admin_email (email),
  KEY ix_admin_status (status, created_at),
  CONSTRAINT ck_admin_role CHECK (role_code IN ('SUPER', 'GENERAL')),
  CONSTRAINT ck_admin_status CHECK (status IN ('ACTIVE', 'SUSPENDED'))
) COMMENT='관리자 원장. 슈퍼 관리자와 일반 관리자';

CREATE TABLE admin_email_challenge (
  id BIGINT NOT NULL AUTO_INCREMENT,
  email VARCHAR(254) NOT NULL,
  purpose VARCHAR(32) NOT NULL,
  code_hash VARCHAR(100) NOT NULL,
  expires_at DATETIME(6) NOT NULL,
  consumed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_admin_challenge (email, purpose, expires_at),
  CONSTRAINT ck_admin_challenge_purpose CHECK (purpose IN ('REGISTER', 'DELETE', 'PASSWORD_CHANGE'))
) COMMENT='관리자 등록, 삭제, 비밀번호 변경 때의 이메일 인증';

CREATE TABLE admin_login_history (
  id BIGINT NOT NULL AUTO_INCREMENT,
  admin_uuid CHAR(36) NOT NULL,
  login_ip VARCHAR(45) NOT NULL,
  client_os VARCHAR(40) NOT NULL,
  logged_in_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_admin_login_history (admin_uuid, logged_in_at)
) COMMENT='관리자 접속 이력';

-- -----------------------------------------------------
-- Schema catalog
-- 상품 쓰기 모델. 판매자 회원은 UUID 스냅샷이다.
-- 카테고리는 이 스키마의 기준정보라 외래키를 둔다.
-- 찜과 시세 조회는 생명주기가 따로라 외래키가 없다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS catalog
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE catalog;

CREATE TABLE category (
  id BIGINT NOT NULL AUTO_INCREMENT,
  parent_id BIGINT NULL,
  category_group VARCHAR(20) NOT NULL,
  depth INT NOT NULL,
  name VARCHAR(80) NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  deleted_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  parent_key BIGINT GENERATED ALWAYS AS (IFNULL(parent_id, 0)) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uk_category_sibling (category_group, parent_key, name),
  KEY ix_category_parent (parent_id),
  CONSTRAINT fk_category_parent
    FOREIGN KEY (parent_id) REFERENCES category (id),
  CONSTRAINT ck_category_group CHECK (category_group IN ('KIND', 'ORIGIN')),
  CONSTRAINT ck_category_depth CHECK (depth >= 1)
) COMMENT='물품 종류와 원산 국가. 같은 부모 아래 이름은 한 번만 등록된다';

CREATE TABLE category_translation (
  category_id BIGINT NOT NULL,
  language_code VARCHAR(8) NOT NULL,
  name VARCHAR(80) NOT NULL,
  PRIMARY KEY (category_id, language_code),
  CONSTRAINT fk_category_translation
    FOREIGN KEY (category_id) REFERENCES category (id),
  CONSTRAINT ck_category_language CHECK (language_code IN ('ko', 'en', 'ja', 'zh-CN', 'zh-TW'))
) COMMENT='화면 언어별 카테고리 이름';

CREATE TABLE product (
  id BIGINT NOT NULL AUTO_INCREMENT,
  product_uuid CHAR(36) NOT NULL,
  seller_uuid CHAR(36) NOT NULL,
  seller_email VARCHAR(254) NULL,
  seller_nickname VARCHAR(30) NOT NULL,
  kind_category_id BIGINT NOT NULL,
  origin_category_id BIGINT NOT NULL,
  title VARCHAR(100) NOT NULL,
  description TEXT NOT NULL,
  price_amount DECIMAL(12,2) NOT NULL,
  delivery_fee_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  sale_status VARCHAR(20) NOT NULL DEFAULT 'ON_SALE',
  deleted_at DATETIME(6) NULL,
  deleted_by_uuid CHAR(36) NULL,
  media_purge_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_product_uuid (product_uuid),
  KEY ix_product_seller (seller_uuid, sale_status),
  KEY ix_product_kind (kind_category_id, sale_status, created_at),
  KEY ix_product_origin (origin_category_id),
  CONSTRAINT fk_product_kind
    FOREIGN KEY (kind_category_id) REFERENCES category (id),
  CONSTRAINT fk_product_origin
    FOREIGN KEY (origin_category_id) REFERENCES category (id),
  CONSTRAINT ck_product_price CHECK (price_amount >= 0 AND price_amount <= 1000000),
  CONSTRAINT ck_product_delivery_fee CHECK (delivery_fee_amount >= 0),
  CONSTRAINT ck_product_currency CHECK (currency_code = 'USD'),
  CONSTRAINT ck_product_sale_status CHECK (sale_status IN ('ON_SALE', 'RESERVED', 'SOLD')),
  CONSTRAINT ck_product_description CHECK (CHAR_LENGTH(description) >= 10)
) COMMENT='판매 상품 원장. 판매완료 이후에는 판매 상태만 바꿀 수 있다';

CREATE TABLE product_media (
  id BIGINT NOT NULL AUTO_INCREMENT,
  product_id BIGINT NOT NULL,
  file_type VARCHAR(10) NOT NULL,
  file_ext VARCHAR(8) NOT NULL,
  object_key VARCHAR(255) NOT NULL,
  file_size BIGINT NOT NULL,
  sort_order INT NOT NULL,
  deleted_at DATETIME(6) NULL,
  purge_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_product_media_order (product_id, sort_order),
  CONSTRAINT fk_product_media_product
    FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT ck_product_media_type CHECK (file_type IN ('IMAGE', 'VIDEO')),
  CONSTRAINT ck_product_media_ext CHECK (file_ext IN ('png', 'jpg', 'jpeg', 'mp4', 'mov')),
  CONSTRAINT ck_product_media_size CHECK (file_size > 0)
) COMMENT='상품 첨부. sort_order 0 이 대표 이미지. 최대 10개는 서비스가 지킨다';

CREATE TABLE product_stat (
  product_id BIGINT NOT NULL,
  wish_count BIGINT NOT NULL DEFAULT 0,
  view_count BIGINT NOT NULL DEFAULT 0,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (product_id),
  CONSTRAINT fk_product_stat_product
    FOREIGN KEY (product_id) REFERENCES product (id),
  CONSTRAINT ck_product_stat_nonnegative CHECK (wish_count >= 0 AND view_count >= 0)
) COMMENT='찜 수와 조회수의 쓰기 측 집계. 목록 화면은 catalog_query 를 본다';

CREATE TABLE product_wish (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_wish_once (member_uuid, product_uuid),
  KEY ix_wish_product (product_uuid),
  KEY ix_wish_member (member_uuid, created_at)
) COMMENT='찜. 상품과 생명주기가 달라 외래키를 두지 않는다';

CREATE TABLE price_quote (
  id BIGINT NOT NULL AUTO_INCREMENT,
  quote_uuid CHAR(36) NOT NULL,
  seller_uuid CHAR(36) NOT NULL,
  image_object_key VARCHAR(255) NOT NULL,
  keyword VARCHAR(255) NOT NULL,
  sample_size INT NOT NULL,
  average_price_amount DECIMAL(12,2) NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_quote_uuid (quote_uuid),
  KEY ix_quote_seller (seller_uuid, created_at),
  CONSTRAINT ck_quote_sample CHECK (sample_size >= 0 AND sample_size <= 100),
  CONSTRAINT ck_quote_currency CHECK (currency_code = 'USD')
) COMMENT='대표 이미지 인식 키워드와 최근 판매완료 100건 평균가';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='상품, 찜, 가격 변경 아웃박스';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='닉네임 변경, 상품 숨김 이벤트의 멱등 키';

INSERT INTO category (category_group, depth, name, sort_order) VALUES
  ('KIND', 1, '피규어/프라모델', 10),
  ('KIND', 1, 'TCG', 20),
  ('KIND', 1, '레고', 30),
  ('KIND', 1, '아트토이', 40),
  ('KIND', 1, '인형', 50),
  ('KIND', 1, '스퀴시/피젯토이', 60),
  ('ORIGIN', 1, '일본', 10),
  ('ORIGIN', 1, '중국', 20),
  ('ORIGIN', 1, '대만', 30),
  ('ORIGIN', 1, '미국', 40),
  ('ORIGIN', 1, '덴마크', 50),
  ('ORIGIN', 1, '체코', 60),
  ('ORIGIN', 1, '독일', 70);

-- -----------------------------------------------------
-- Schema trade
-- 거래 쓰기 모델. 상품, 회원, 결제, 배송은 UUID 와 구매 시점 스냅샷이다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS trade
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE trade;

CREATE TABLE cancel_reason (
  id BIGINT NOT NULL AUTO_INCREMENT,
  reason_code VARCHAR(40) NOT NULL,
  label VARCHAR(100) NOT NULL,
  sort_order INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_cancel_reason (reason_code)
) COMMENT='거래 취소 사유 기준정보';

CREATE TABLE trade (
  id BIGINT NOT NULL AUTO_INCREMENT,
  trade_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  seller_uuid CHAR(36) NOT NULL,
  buyer_uuid CHAR(36) NOT NULL,
  phase VARCHAR(32) NOT NULL,
  payment_status VARCHAR(32) NOT NULL,
  seller_nickname VARCHAR(30) NOT NULL,
  buyer_nickname VARCHAR(30) NOT NULL,
  seller_email VARCHAR(254) NOT NULL,
  buyer_email VARCHAR(254) NOT NULL,
  product_title VARCHAR(100) NOT NULL,
  product_thumbnail_key VARCHAR(255) NOT NULL,
  product_price_amount DECIMAL(12,2) NOT NULL,
  delivery_fee_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  membership_applied TINYINT(1) NOT NULL DEFAULT 0,
  fee_rate_percent DECIMAL(5,2) NULL,
  buyer_recipient_name VARCHAR(100) NULL,
  buyer_phone VARCHAR(30) NULL,
  buyer_address_line VARCHAR(255) NULL,
  buyer_address_detail VARCHAR(150) NULL,
  buyer_postcode VARCHAR(20) NULL,
  customs_clearance_code VARCHAR(30) NULL,
  seller_recipient_name VARCHAR(100) NULL,
  seller_phone VARCHAR(30) NULL,
  seller_address_line VARCHAR(255) NULL,
  seller_address_detail VARCHAR(150) NULL,
  seller_postcode VARCHAR(20) NULL,
  payout_holder_name VARCHAR(100) NULL,
  payout_bank_name VARCHAR(100) NULL,
  payout_bank_code VARCHAR(20) NULL,
  payout_account_cipher VARCHAR(512) NULL,
  payout_encryption_key_id VARCHAR(64) NULL,
  cancel_reason_code VARCHAR(40) NULL,
  cancel_detail VARCHAR(500) NULL,
  canceled_by_uuid CHAR(36) NULL,
  accept_due_at DATETIME(6) NULL,
  accepted_at DATETIME(6) NULL,
  paid_at DATETIME(6) NULL,
  delivered_at DATETIME(6) NULL,
  confirm_due_at DATETIME(6) NULL,
  confirmed_at DATETIME(6) NULL,
  cancel_requested_at DATETIME(6) NULL,
  canceled_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_trade_uuid (trade_uuid),
  KEY ix_trade_buyer (buyer_uuid, phase, created_at),
  KEY ix_trade_seller (seller_uuid, phase, created_at),
  KEY ix_trade_product (product_uuid),
  KEY ix_trade_accept_due (phase, accept_due_at),
  KEY ix_trade_confirm_due (phase, confirm_due_at),
  CONSTRAINT ck_trade_phase CHECK (phase IN (
    'REQUESTED', 'AWAITING_PAYMENT', 'PAID', 'SHIPPING', 'DELIVERED',
    'CONFIRMED', 'CANCEL_REQUESTED', 'CANCELED'
  )),
  CONSTRAINT ck_trade_payment_status CHECK (payment_status IN ('PENDING', 'PAID', 'CANCELED', 'REFUND_PENDING', 'REFUNDED')),
  CONSTRAINT ck_trade_price CHECK (product_price_amount >= 0 AND product_price_amount <= 1000000),
  CONSTRAINT ck_trade_currency CHECK (currency_code = 'USD')
) COMMENT='거래 원장. 구매 내역 화면은 결제 완료 후 trade_query 에만 보인다';

CREATE TABLE trade_status_log (
  id BIGINT NOT NULL AUTO_INCREMENT,
  trade_id BIGINT NOT NULL,
  from_phase VARCHAR(32) NULL,
  to_phase VARCHAR(32) NOT NULL,
  actor_uuid CHAR(36) NULL,
  reason_text VARCHAR(200) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_trade_status_log (trade_id, created_at),
  CONSTRAINT fk_trade_status_log
    FOREIGN KEY (trade_id) REFERENCES trade (id)
) COMMENT='거래 단계 이력. 거래 애그리거트의 자식';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='거래 단계 변경 아웃박스';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='결제, 배송, 정산 이벤트를 거래에 한 번만 반영하는 멱등 키';

INSERT INTO cancel_reason (reason_code, label, sort_order) VALUES
  ('CHANGED_MIND', '단순 변심', 10),
  ('NOT_AS_DESCRIBED', '상품 설명과 다름', 20),
  ('DAMAGED', '파손 또는 하자', 30),
  ('SELLER_UNRESPONSIVE', '판매자 미응답', 40),
  ('OTHER', '기타', 50);

-- -----------------------------------------------------
-- Schema payment
-- 안전결제. 거래와 회원은 UUID 다. 웹훅 이벤트 번호로 중복 반영을 막는다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS payment
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE payment;

CREATE TABLE payment (
  id BIGINT NOT NULL AUTO_INCREMENT,
  payment_uuid CHAR(36) NOT NULL,
  trade_uuid CHAR(36) NOT NULL,
  buyer_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  method_code VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'READY',
  provider_name VARCHAR(20) NOT NULL DEFAULT 'STRIPE',
  provider_intent_id VARCHAR(255) NULL,
  provider_charge_id VARCHAR(255) NULL,
  product_name_snapshot VARCHAR(100) NOT NULL,
  terms_code VARCHAR(40) NOT NULL,
  terms_version VARCHAR(40) NOT NULL,
  terms_agreed_at DATETIME(6) NOT NULL,
  idempotency_key VARCHAR(120) NOT NULL,
  approved_at DATETIME(6) NULL,
  failed_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_payment_uuid (payment_uuid),
  UNIQUE KEY uk_payment_idempotency (idempotency_key),
  KEY ix_payment_trade (trade_uuid, status),
  KEY ix_payment_intent (provider_intent_id),
  CONSTRAINT ck_payment_amount CHECK (amount >= 0),
  CONSTRAINT ck_payment_currency CHECK (currency_code = 'USD'),
  CONSTRAINT ck_payment_method CHECK (method_code IN ('CARD', 'MOBILE', 'PAYPAL', 'APPLE_PAY', 'GOOGLE_PAY')),
  CONSTRAINT ck_payment_status CHECK (status IN ('READY', 'SUCCEEDED', 'FAILED', 'CANCELED'))
) COMMENT='결제 시도 원장. 재시도는 새 행과 새 멱등 키로 남긴다';

CREATE TABLE payment_webhook (
  provider_event_id VARCHAR(255) NOT NULL,
  payment_uuid CHAR(36) NULL,
  received_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  processed_at DATETIME(6) NULL,
  PRIMARY KEY (provider_event_id)
) COMMENT='PG 웹훅 수신 멱등 키. 본문 원문은 결제 서비스 로그에 두고 여기에는 처리 여부만 둔다';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='결제 성공, 실패, 취소 아웃박스';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='거래 취소에 따른 결제 취소 이벤트의 멱등 키';

-- -----------------------------------------------------
-- Schema settlement
-- 구매 확정 후 판매자 지급, 취소 확정 후 구매자 환급.
-- 수수료율은 지급 시점의 스냅샷이다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS settlement
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE settlement;

CREATE TABLE fee_policy (
  id BIGINT NOT NULL AUTO_INCREMENT,
  policy_code VARCHAR(30) NOT NULL,
  rate_percent DECIMAL(5,2) NOT NULL,
  description VARCHAR(200) NOT NULL,
  effective_from DATETIME(6) NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_fee_policy (policy_code),
  CONSTRAINT ck_fee_rate CHECK (rate_percent >= 0 AND rate_percent <= 100)
) COMMENT='수수료 기준정보. 일반 10%, 멤버십 6%';

CREATE TABLE settlement (
  id BIGINT NOT NULL AUTO_INCREMENT,
  settlement_uuid CHAR(36) NOT NULL,
  trade_uuid CHAR(36) NOT NULL,
  payee_uuid CHAR(36) NOT NULL,
  settlement_type VARCHAR(20) NOT NULL,
  status VARCHAR(20) NOT NULL,
  gross_amount DECIMAL(15,2) NOT NULL,
  fee_amount DECIMAL(15,2) NOT NULL,
  net_amount DECIMAL(15,2) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  fee_policy_id BIGINT NOT NULL,
  fee_rate_percent DECIMAL(5,2) NOT NULL,
  holder_name VARCHAR(100) NOT NULL,
  bank_name VARCHAR(100) NOT NULL,
  bank_code VARCHAR(20) NOT NULL,
  account_number_cipher VARCHAR(512) NOT NULL,
  encryption_key_id VARCHAR(64) NOT NULL,
  external_transfer_id VARCHAR(150) NULL,
  idempotency_key VARCHAR(120) NOT NULL,
  due_at DATETIME(6) NOT NULL,
  requested_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  completed_at DATETIME(6) NULL,
  canceled_at DATETIME(6) NULL,
  failure_reason VARCHAR(500) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_settlement_uuid (settlement_uuid),
  UNIQUE KEY uk_settlement_idempotency (idempotency_key),
  KEY ix_settlement_trade (trade_uuid, settlement_type),
  KEY ix_settlement_status (status, requested_at),
  KEY ix_settlement_due (status, due_at),
  CONSTRAINT fk_settlement_fee_policy
    FOREIGN KEY (fee_policy_id) REFERENCES fee_policy (id),
  CONSTRAINT ck_settlement_type CHECK (settlement_type IN ('SELLER_PAYOUT', 'BUYER_REFUND')),
  CONSTRAINT ck_settlement_status CHECK (status IN ('REQUESTED', 'PROCESSING', 'COMPLETED', 'CANCELED', 'FAILED')),
  CONSTRAINT ck_settlement_amount CHECK (gross_amount >= 0 AND fee_amount >= 0 AND net_amount >= 0),
  CONSTRAINT ck_settlement_currency CHECK (currency_code = 'USD')
) COMMENT='정산과 환급. 구매 확정 또는 취소 확정 후 1시간 이내 지급이 기준이다';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='정산 상태 아웃박스';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='구매 확정, 취소 확정 이벤트의 멱등 키';

INSERT INTO fee_policy (policy_code, rate_percent, description, effective_from) VALUES
  ('STANDARD', 10.00, '일반 판매 수수료', '2026-01-01 00:00:00.000000'),
  ('MEMBERSHIP', 6.00, '멤버십 적용 판매 수수료', '2026-01-01 00:00:00.000000');

-- -----------------------------------------------------
-- Schema fulfillment
-- 운송장과 택배 스캔 이력. 수초 단위 좌표는 요구사항에 없으므로 두지 않는다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS fulfillment
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE fulfillment;

CREATE TABLE shipment (
  id BIGINT NOT NULL AUTO_INCREMENT,
  shipment_uuid CHAR(36) NOT NULL,
  trade_uuid CHAR(36) NOT NULL,
  courier_name VARCHAR(50) NOT NULL,
  tracking_number VARCHAR(64) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'READY',
  shipped_at DATETIME(6) NULL,
  delivered_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_shipment_uuid (shipment_uuid),
  UNIQUE KEY uk_shipment_trade (trade_uuid),
  KEY ix_shipment_tracking (courier_name, tracking_number),
  CONSTRAINT ck_shipment_status CHECK (status IN ('READY', 'SHIPPED', 'DELIVERED'))
) COMMENT='거래당 배송 하나. 배송 완료 시각이 구매 확정 5일의 기산점이다';

CREATE TABLE shipment_checkpoint (
  id BIGINT NOT NULL AUTO_INCREMENT,
  shipment_id BIGINT NOT NULL,
  status_code VARCHAR(40) NOT NULL,
  description VARCHAR(255) NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  KEY ix_checkpoint_shipment (shipment_id, occurred_at),
  CONSTRAINT fk_checkpoint_shipment
    FOREIGN KEY (shipment_id) REFERENCES shipment (id)
) COMMENT='택배사 조회 스캔. 좌표 스트림이 아니므로 MySQL 에 둔다';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='출고, 배송 완료 아웃박스';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='결제 완료 뒤 배송 행을 만드는 이벤트의 멱등 키';

-- -----------------------------------------------------
-- Schema chat
-- 방과 참여자 상태만 MySQL 에 둔다. 메시지 본문은 MongoDB respark_chat.messages 다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS chat
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE chat;

CREATE TABLE chat_room (
  id BIGINT NOT NULL AUTO_INCREMENT,
  room_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  buyer_uuid CHAR(36) NOT NULL,
  seller_uuid CHAR(36) NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'OPEN',
  last_message_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_room_uuid (room_uuid),
  UNIQUE KEY uk_room_product_buyer (product_uuid, buyer_uuid),
  KEY ix_room_seller (seller_uuid, last_message_at),
  KEY ix_room_buyer (buyer_uuid, last_message_at),
  CONSTRAINT ck_room_status CHECK (status IN ('OPEN', 'CLOSED')),
  CONSTRAINT ck_room_participants CHECK (buyer_uuid <> seller_uuid)
) COMMENT='상품당 구매자-판매자 1대1 방. 첫 메시지 전 last_message_at 은 NULL 이라 목록에서 빠진다';

CREATE TABLE chat_participant (
  id BIGINT NOT NULL AUTO_INCREMENT,
  room_id BIGINT NOT NULL,
  member_uuid CHAR(36) NOT NULL,
  participant_role VARCHAR(20) NOT NULL,
  left_at DATETIME(6) NULL,
  unread_count INT NOT NULL DEFAULT 0,
  send_locked_until DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_participant (room_id, member_uuid),
  KEY ix_participant_member (member_uuid),
  CONSTRAINT fk_participant_room
    FOREIGN KEY (room_id) REFERENCES chat_room (id),
  CONSTRAINT ck_participant_role CHECK (participant_role IN ('BUYER', 'SELLER')),
  CONSTRAINT ck_participant_unread CHECK (unread_count >= 0)
) COMMENT='나가기는 left_at 영구 표시. 1초 5회 초과 시 send_locked_until 로 10초를 막는다';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='채팅 알림용 아웃박스. 본문은 넣지 않고 message_uuid 만 담는다';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='거래 서비스의 시스템 메시지 요청을 한 번만 반영하는 멱등 키';

-- -----------------------------------------------------
-- Schema notification
-- 알림 템플릿, 수신 설정, 수신함. 수신함은 회원당 50건을 넘는 가장 오래된 행을 지운다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS notification
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE notification;

CREATE TABLE notification_template (
  id BIGINT NOT NULL AUTO_INCREMENT,
  template_code VARCHAR(40) NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  writer_admin_uuid CHAR(36) NOT NULL,
  editor_admin_uuid CHAR(36) NULL,
  deleted_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_template_code (template_code)
) COMMENT='관리자가 고치는 알림 문구. 발송 행은 제목과 본문을 따로 복사한다';

CREATE TABLE notification_preference (
  id BIGINT NOT NULL AUTO_INCREMENT,
  member_uuid CHAR(36) NOT NULL,
  template_id BIGINT NOT NULL,
  enabled TINYINT(1) NOT NULL DEFAULT 1,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_preference (member_uuid, template_id),
  CONSTRAINT fk_preference_template
    FOREIGN KEY (template_id) REFERENCES notification_template (id)
) COMMENT='회원 알림 수신 설정. 탈퇴 시 이 행은 하드 딜리트한다';

CREATE TABLE notification_inbox (
  id BIGINT NOT NULL AUTO_INCREMENT,
  inbox_uuid CHAR(36) NOT NULL,
  member_uuid CHAR(36) NOT NULL,
  template_code VARCHAR(40) NOT NULL,
  title VARCHAR(200) NOT NULL,
  body TEXT NOT NULL,
  related_type VARCHAR(40) NULL,
  related_uuid CHAR(36) NULL,
  sent_at DATETIME(6) NOT NULL,
  read_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_inbox_uuid (inbox_uuid),
  KEY ix_inbox_member (member_uuid, sent_at, id)
) COMMENT='수신함. 소프트 딜리트 없이 50건 초과분부터 오래된 순으로 삭제한다';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='알림 발송 사실의 아웃박스';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='가격 하락, 채팅, 거래 이벤트를 수신함에 한 번만 넣는 멱등 키';

INSERT INTO notification_template (template_code, title, body, writer_admin_uuid) VALUES
  ('PRICE_DROP', '찜한 상품의 가격이 내려갔습니다', '{productTitle} 가격이 {oldPrice} 에서 {newPrice} 로 변경되었습니다.', '00000000-0000-0000-0000-000000000001'),
  ('PRICE_OFFER', '가격 제안이 도착했습니다', '{productTitle} 에 새로운 가격 제안이 있습니다.', '00000000-0000-0000-0000-000000000001'),
  ('CHAT', '새 채팅 메시지', '새 메시지가 도착했습니다.', '00000000-0000-0000-0000-000000000001'),
  ('TRADE', '거래 상태가 변경되었습니다', '{productTitle} 거래가 {phase} 상태입니다.', '00000000-0000-0000-0000-000000000001');

-- -----------------------------------------------------
-- Schema review
-- 구매 확정 이후 거래 당사자 리뷰. 첨부 포함 3개월 보관.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS review
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE review;

CREATE TABLE review (
  id BIGINT NOT NULL AUTO_INCREMENT,
  review_uuid CHAR(36) NOT NULL,
  trade_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  writer_uuid CHAR(36) NOT NULL,
  target_uuid CHAR(36) NOT NULL,
  writer_role VARCHAR(20) NOT NULL,
  rating TINYINT NOT NULL,
  content TEXT NULL,
  deleted_at DATETIME(6) NULL,
  purge_at DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_review_uuid (review_uuid),
  UNIQUE KEY uk_review_once (trade_uuid, writer_uuid),
  KEY ix_review_target (target_uuid, created_at),
  KEY ix_review_purge (purge_at),
  CONSTRAINT ck_review_role CHECK (writer_role IN ('BUYER', 'SELLER')),
  CONSTRAINT ck_review_rating CHECK (rating BETWEEN 1 AND 5),
  CONSTRAINT ck_review_parties CHECK (writer_uuid <> target_uuid)
) COMMENT='거래 상대에 대한 리뷰. 작성자와 대상이 뒤바뀌지 않도록 역할을 컬럼으로 둔다';

CREATE TABLE review_media (
  id BIGINT NOT NULL AUTO_INCREMENT,
  review_id BIGINT NOT NULL,
  file_type VARCHAR(10) NOT NULL,
  file_ext VARCHAR(8) NOT NULL,
  object_key VARCHAR(255) NOT NULL,
  file_size BIGINT NOT NULL,
  sort_order INT NOT NULL,
  deleted_at DATETIME(6) NULL,
  purge_at DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_review_media_order (review_id, sort_order),
  CONSTRAINT fk_review_media_review
    FOREIGN KEY (review_id) REFERENCES review (id),
  CONSTRAINT ck_review_media_type CHECK (file_type IN ('IMAGE', 'VIDEO')),
  CONSTRAINT ck_review_media_ext CHECK (file_ext IN ('png', 'jpg', 'jpeg', 'mp4', 'mov')),
  CONSTRAINT ck_review_media_size CHECK (file_size > 0),
  CONSTRAINT ck_review_media_order CHECK (sort_order IN (0, 1))
) COMMENT='리뷰 첨부. 사진과 동영상을 합쳐 최대 2개';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='리뷰 작성, 삭제 아웃박스. 프로필 평점 조회 모델이 소비한다';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='신고 수락으로 리뷰를 숨기는 이벤트의 멱등 키';

-- -----------------------------------------------------
-- Schema support
-- 공지, FAQ, 문의, 금지 품목을 게시판 설정과 게시글 애그리거트로 둔다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS support
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE support;

CREATE TABLE board (
  id BIGINT NOT NULL AUTO_INCREMENT,
  board_code VARCHAR(30) NOT NULL,
  name VARCHAR(100) NOT NULL,
  user_writable TINYINT(1) NOT NULL,
  status_enabled TINYINT(1) NOT NULL,
  pin_enabled TINYINT(1) NOT NULL,
  schedule_enabled TINYINT(1) NOT NULL,
  media_enabled TINYINT(1) NOT NULL,
  deletable TINYINT(1) NOT NULL,
  in_use TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_board_code (board_code)
) COMMENT='게시판 동작 스위치. 문의는 deletable = 0 이라 사용자가 지우지 못한다';

CREATE TABLE board_category (
  id BIGINT NOT NULL AUTO_INCREMENT,
  board_id BIGINT NOT NULL,
  parent_id BIGINT NULL,
  name VARCHAR(80) NOT NULL,
  depth INT NOT NULL,
  sort_order INT NOT NULL DEFAULT 0,
  deleted_at DATETIME(6) NULL,
  parent_key BIGINT GENERATED ALWAYS AS (IFNULL(parent_id, 0)) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uk_board_category_sibling (board_id, parent_key, name),
  KEY ix_board_category_parent (parent_id),
  CONSTRAINT fk_board_category_board
    FOREIGN KEY (board_id) REFERENCES board (id),
  CONSTRAINT fk_board_category_parent
    FOREIGN KEY (parent_id) REFERENCES board_category (id),
  CONSTRAINT ck_board_category_depth CHECK (depth >= 1)
) COMMENT='게시판 분류. 상품 카테고리와 섞지 않는다';

CREATE TABLE post (
  id BIGINT NOT NULL AUTO_INCREMENT,
  post_uuid CHAR(36) NOT NULL,
  board_id BIGINT NOT NULL,
  category_id BIGINT NOT NULL,
  writer_uuid CHAR(36) NOT NULL,
  editor_uuid CHAR(36) NULL,
  title VARCHAR(200) NOT NULL,
  content TEXT NOT NULL,
  pinned TINYINT(1) NOT NULL DEFAULT 0,
  published TINYINT(1) NOT NULL DEFAULT 0,
  publish_at DATETIME(6) NULL,
  expose_until DATETIME(6) NULL,
  inquiry_status VARCHAR(20) NULL,
  view_count BIGINT NOT NULL DEFAULT 0,
  deleted_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_post_uuid (post_uuid),
  KEY ix_post_board (board_id, published, pinned, publish_at),
  KEY ix_post_writer (writer_uuid, created_at),
  KEY ix_post_category (category_id, created_at),
  CONSTRAINT fk_post_board
    FOREIGN KEY (board_id) REFERENCES board (id),
  CONSTRAINT fk_post_category
    FOREIGN KEY (category_id) REFERENCES board_category (id),
  CONSTRAINT ck_post_inquiry_status CHECK (inquiry_status IS NULL OR inquiry_status IN ('RECEIVED', 'ANSWERED')),
  CONSTRAINT ck_post_view CHECK (view_count >= 0)
) COMMENT='공지, FAQ, 문의, 금지 품목 본문';

CREATE TABLE post_media (
  id BIGINT NOT NULL AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  object_key VARCHAR(255) NOT NULL,
  file_size BIGINT NOT NULL,
  sort_order INT NOT NULL,
  deleted_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_post_media_order (post_id, sort_order),
  CONSTRAINT fk_post_media_post
    FOREIGN KEY (post_id) REFERENCES post (id),
  CONSTRAINT ck_post_media_order CHECK (sort_order BETWEEN 0 AND 4),
  CONSTRAINT ck_post_media_size CHECK (file_size > 0)
) COMMENT='게시글 사진. 최대 5장';

CREATE TABLE post_reply (
  id BIGINT NOT NULL AUTO_INCREMENT,
  post_id BIGINT NOT NULL,
  admin_uuid CHAR(36) NOT NULL,
  content TEXT NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_post_reply_once (post_id),
  CONSTRAINT fk_post_reply_post
    FOREIGN KEY (post_id) REFERENCES post (id)
) COMMENT='문의 답변. 게시글당 하나';

CREATE TABLE outbox_event (
  id BIGINT NOT NULL AUTO_INCREMENT,
  event_id CHAR(36) NOT NULL,
  aggregate_type VARCHAR(40) NOT NULL,
  aggregate_uuid CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  payload JSON NOT NULL,
  occurred_at DATETIME(6) NOT NULL,
  published_at DATETIME(6) NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_outbox_event (event_id),
  KEY ix_outbox_unpublished (published_at, id)
) COMMENT='문의 답변 알림 등을 위한 아웃박스';

INSERT INTO board (board_code, name, user_writable, status_enabled, pin_enabled, schedule_enabled, media_enabled, deletable) VALUES
  ('NOTICE', '공지사항', 0, 0, 1, 1, 1, 1),
  ('FAQ', '자주 묻는 질문', 0, 0, 0, 0, 0, 1),
  ('INQUIRY', '1:1 문의', 1, 1, 0, 0, 1, 0),
  ('PROHIBITED', '금지 품목', 0, 0, 0, 0, 0, 1);

INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '일반', 1, 10 FROM board WHERE board_code = 'NOTICE';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '정책변경', 1, 20 FROM board WHERE board_code = 'NOTICE';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '사기예방', 1, 30 FROM board WHERE board_code = 'NOTICE';

INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '회원/계정', 1, 10 FROM board WHERE board_code = 'FAQ';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '거래 분쟁 운영정책', 1, 20 FROM board WHERE board_code = 'FAQ';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '안전결제', 1, 30 FROM board WHERE board_code = 'FAQ';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '상품', 1, 40 FROM board WHERE board_code = 'FAQ';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '배송', 1, 50 FROM board WHERE board_code = 'FAQ';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '환불', 1, 60 FROM board WHERE board_code = 'FAQ';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '정산', 1, 70 FROM board WHERE board_code = 'FAQ';

INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '배송', 1, 10 FROM board WHERE board_code = 'INQUIRY';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '구매', 1, 20 FROM board WHERE board_code = 'INQUIRY';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '반품', 1, 30 FROM board WHERE board_code = 'INQUIRY';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '결제', 1, 40 FROM board WHERE board_code = 'INQUIRY';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '기타', 1, 50 FROM board WHERE board_code = 'INQUIRY';

INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '인화성 및 위험물질', 1, 10 FROM board WHERE board_code = 'PROHIBITED';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '총 및 칼 등 불법 위해물품', 1, 20 FROM board WHERE board_code = 'PROHIBITED';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '화폐 및 유가증권', 1, 30 FROM board WHERE board_code = 'PROHIBITED';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '약재 및 의약품', 1, 40 FROM board WHERE board_code = 'PROHIBITED';
INSERT INTO board_category (board_id, name, depth, sort_order)
SELECT id, '음식물', 1, 50 FROM board WHERE board_code = 'PROHIBITED';

-- -----------------------------------------------------
-- Schema moderation
-- 신고, 제재, 누적 횟수. 회원, 상품, 사유, 처리 관리자는 UUID 값만 담는다.
-- 수락이 3회를 넘으면 strike_policy 의 동작을 적용한다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS moderation
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE moderation;

CREATE TABLE report_reason (
  id BIGINT NOT NULL AUTO_INCREMENT,
  reason_uuid CHAR(36) NOT NULL,
  reason_code VARCHAR(40) NOT NULL,
  label VARCHAR(100) NOT NULL,
  sort_order INT NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uk_reason_uuid (reason_uuid),
  UNIQUE KEY uk_report_reason (reason_code)
) COMMENT='신고 사유 기준정보';

CREATE TABLE strike_policy (
  target_type VARCHAR(20) NOT NULL,
  threshold_count INT NOT NULL,
  action_code VARCHAR(40) NOT NULL,
  PRIMARY KEY (target_type),
  CONSTRAINT ck_strike_target CHECK (target_type IN ('PRODUCT', 'MEMBER', 'REVIEW', 'CHAT')),
  CONSTRAINT ck_strike_threshold CHECK (threshold_count > 0)
) COMMENT='수락 누적이 이 값을 넘으면 자동 조치. 3회 초과이므로 기본값은 3';

CREATE TABLE report (
  id BIGINT NOT NULL AUTO_INCREMENT,
  report_uuid CHAR(36) NOT NULL,
  reporter_uuid CHAR(36) NOT NULL,
  target_type VARCHAR(20) NOT NULL,
  target_uuid CHAR(36) NOT NULL,
  reason_uuid CHAR(36) NOT NULL,
  description TEXT NOT NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'RECEIVED',
  admin_uuid CHAR(36) NULL,
  decided_at DATETIME(6) NULL,
  deleted_at DATETIME(6) NULL,
  purge_at DATETIME(6) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_report_uuid (report_uuid),
  KEY ix_report_queue (status, created_at),
  KEY ix_report_target (target_type, target_uuid),
  KEY ix_report_reporter (reporter_uuid, created_at),
  KEY ix_report_reason (reason_uuid),
  KEY ix_report_purge (purge_at),
  CONSTRAINT ck_report_target CHECK (target_type IN ('PRODUCT', 'MEMBER', 'REVIEW', 'CHAT')),
  CONSTRAINT ck_report_status CHECK (status IN ('RECEIVED', 'ACCEPTED', 'REJECTED'))
) COMMENT='신고 원장. 접수자는 작성 내용을 다시 조회하거나 수정하지 않는다';

CREATE TABLE report_media (
  id BIGINT NOT NULL AUTO_INCREMENT,
  report_uuid CHAR(36) NOT NULL,
  object_key VARCHAR(255) NOT NULL,
  file_size BIGINT NOT NULL,
  sort_order INT NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_report_media_order (report_uuid, sort_order),
  KEY ix_report_media_report (report_uuid),
  CONSTRAINT ck_report_media_order CHECK (sort_order BETWEEN 0 AND 4),
  CONSTRAINT ck_report_media_size CHECK (file_size > 0)
) COMMENT='신고 첨부. 최대 5장이고 수정 컬럼이 없다';

CREATE TABLE sanction (
  id BIGINT NOT NULL AUTO_INCREMENT,
  sanction_uuid CHAR(36) NOT NULL,
  member_uuid CHAR(36) NOT NULL,
  source_report_uuid CHAR(36) NULL,
  reason_text VARCHAR(200) NOT NULL,
  starts_at DATETIME(6) NOT NULL,
  ends_at DATETIME(6) NOT NULL,
  status VARCHAR(20) NOT NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (id),
  UNIQUE KEY uk_sanction_uuid (sanction_uuid),
  KEY ix_sanction_member (member_uuid, starts_at),
  KEY ix_sanction_report (source_report_uuid),
  CONSTRAINT ck_sanction_status CHECK (status IN ('ACTIVE', 'FINISHED')),
  CONSTRAINT ck_sanction_period CHECK (ends_at > starts_at)
) COMMENT='활동 정지 이력. 기본 자동 정지는 3일이다';

CREATE TABLE strike_counter (
  target_type VARCHAR(20) NOT NULL,
  target_uuid CHAR(36) NOT NULL,
  accepted_count INT NOT NULL DEFAULT 0,
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  PRIMARY KEY (target_type, target_uuid),
  CONSTRAINT ck_strike_counter_target CHECK (target_type IN ('PRODUCT', 'MEMBER', 'REVIEW', 'CHAT')),
  CONSTRAINT ck_strike_counter_count CHECK (accepted_count >= 0)
) COMMENT='대상별 수락된 신고 수';

INSERT INTO report_reason (reason_uuid, reason_code, label, sort_order) VALUES
  ('b2000001-0000-4000-8000-000000000001', 'FRAUD', '사기 의심', 10),
  ('b2000001-0000-4000-8000-000000000002', 'ABUSE', '욕설 및 비방', 20),
  ('b2000001-0000-4000-8000-000000000003', 'SPAM', '광고 및 도배', 30),
  ('b2000001-0000-4000-8000-000000000004', 'PROHIBITED_ITEM', '판매 금지 상품', 40),
  ('b2000001-0000-4000-8000-000000000005', 'OTHER', '기타', 50);

INSERT INTO strike_policy (target_type, threshold_count, action_code) VALUES
  ('PRODUCT', 3, 'HIDE_PRODUCT'),
  ('MEMBER', 3, 'SUSPEND_MEMBER_3D'),
  ('REVIEW', 3, 'HIDE_REVIEW'),
  ('CHAT', 3, 'SUSPEND_MEMBER_3D');

-- -----------------------------------------------------
-- Schema membership
-- 구독 상품과 회원 구독. 결제 승인 자체는 payment 스키마가 가진다.
-- 회원과 상품은 UUID 값만 가리킨다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS membership
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE membership;

CREATE TABLE membership_plan (
  id BIGINT NOT NULL AUTO_INCREMENT,
  plan_uuid CHAR(36) NOT NULL,
  plan_code VARCHAR(30) NOT NULL,
  price_amount DECIMAL(12,2) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  billing_cycle VARCHAR(20) NOT NULL,
  description VARCHAR(500) NOT NULL,
  in_use TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uk_plan_uuid (plan_uuid),
  UNIQUE KEY uk_plan_code (plan_code),
  CONSTRAINT ck_plan_price CHECK (price_amount >= 0),
  CONSTRAINT ck_plan_currency CHECK (currency_code = 'USD'),
  CONSTRAINT ck_plan_cycle CHECK (billing_cycle IN ('MONTHLY'))
) COMMENT='멤버십 상품 기준정보';

CREATE TABLE subscription (
  id BIGINT NOT NULL AUTO_INCREMENT,
  subscription_uuid CHAR(36) NOT NULL,
  member_uuid CHAR(36) NOT NULL,
  plan_uuid CHAR(36) NOT NULL,
  status VARCHAR(20) NOT NULL,
  current_period_start DATETIME(6) NOT NULL,
  current_period_end DATETIME(6) NOT NULL,
  next_billing_at DATETIME(6) NULL,
  canceled_at DATETIME(6) NULL,
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),
  active_marker CHAR(36)
    GENERATED ALWAYS AS (CASE WHEN status = 'ACTIVE' THEN member_uuid ELSE NULL END) STORED,
  PRIMARY KEY (id),
  UNIQUE KEY uk_subscription_uuid (subscription_uuid),
  UNIQUE KEY uk_subscription_one_active (active_marker),
  KEY ix_subscription_member (member_uuid, status),
  KEY ix_subscription_plan (plan_uuid),
  CONSTRAINT ck_subscription_status CHECK (status IN ('ACTIVE', 'CANCELED', 'PAST_DUE')),
  CONSTRAINT ck_subscription_period CHECK (current_period_end > current_period_start)
) COMMENT='회원 구독. 활성 구독은 회원당 하나';

INSERT INTO membership_plan (plan_uuid, plan_code, price_amount, billing_cycle, description) VALUES
  ('c3000001-0000-4000-8000-000000000001', 'SELLER_MONTHLY', 9.99, 'MONTHLY', '월간 멤버십. 결제 시점의 판매 수수료는 6% 를 적용한다.');

-- -----------------------------------------------------
-- Schema catalog_query
-- 상품 목록, 검색, 시세의 조회 모델. 쓰기 테이블과 조인하지 않는다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS catalog_query
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE catalog_query;

CREATE TABLE product_card (
  product_uuid CHAR(36) NOT NULL,
  seller_uuid CHAR(36) NOT NULL,
  seller_email VARCHAR(254) NULL,
  seller_nickname VARCHAR(30) NOT NULL,
  kind_category_id BIGINT NOT NULL,
  kind_name VARCHAR(80) NOT NULL,
  origin_category_id BIGINT NOT NULL,
  origin_name VARCHAR(80) NOT NULL,
  title VARCHAR(100) NOT NULL,
  price_amount DECIMAL(12,2) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  sale_status VARCHAR(20) NOT NULL,
  thumbnail_key VARCHAR(255) NULL,
  wish_count BIGINT NOT NULL DEFAULT 0,
  view_count BIGINT NOT NULL DEFAULT 0,
  deleted_flag TINYINT(1) NOT NULL DEFAULT 0,
  listed_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (product_uuid),
  KEY ix_card_list (deleted_flag, sale_status, kind_category_id, origin_category_id, listed_at),
  KEY ix_card_price (deleted_flag, sale_status, price_amount),
  KEY ix_card_popular (deleted_flag, sale_status, wish_count, view_count),
  KEY ix_card_seller (seller_uuid, sale_status),
  FULLTEXT KEY ft_card_title (title) WITH PARSER ngram
) COMMENT='목록, 검색, 메인 추천이 읽는 상품 카드';

CREATE TABLE sold_price (
  trade_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  title VARCHAR(100) NOT NULL,
  keyword_text VARCHAR(255) NOT NULL,
  price_amount DECIMAL(12,2) NOT NULL,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  sold_at DATETIME(6) NOT NULL,
  PRIMARY KEY (trade_uuid),
  KEY ix_sold_recent (sold_at),
  FULLTEXT KEY ft_sold_keyword (keyword_text, title) WITH PARSER ngram
) COMMENT='판매 완료 가격. 시세는 이 표에서 최근 100건 평균을 계산한다';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='catalog_query 멱등 키';

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

-- -----------------------------------------------------
-- Schema trade_query
-- 구매 내역, 판매 내역, 관리자 거래 목록. 결제 완료 전 행은 넣지 않는다.
-- -----------------------------------------------------
CREATE DATABASE IF NOT EXISTS trade_query
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_0900_ai_ci;
USE trade_query;

CREATE TABLE trade_card (
  trade_uuid CHAR(36) NOT NULL,
  product_uuid CHAR(36) NOT NULL,
  seller_uuid CHAR(36) NOT NULL,
  buyer_uuid CHAR(36) NOT NULL,
  seller_nickname VARCHAR(30) NOT NULL,
  buyer_nickname VARCHAR(30) NOT NULL,
  seller_email VARCHAR(254) NOT NULL,
  buyer_email VARCHAR(254) NOT NULL,
  product_title VARCHAR(100) NOT NULL,
  thumbnail_key VARCHAR(255) NOT NULL,
  price_amount DECIMAL(12,2) NOT NULL,
  delivery_fee_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  currency_code CHAR(3) NOT NULL DEFAULT 'USD',
  phase VARCHAR(32) NOT NULL,
  list_bucket VARCHAR(20) NOT NULL,
  payment_status VARCHAR(32) NOT NULL,
  payment_method VARCHAR(20) NULL,
  paid_at DATETIME(6) NULL,
  settlement_status VARCHAR(20) NULL,
  settlement_amount DECIMAL(15,2) NULL,
  fee_amount DECIMAL(15,2) NULL,
  settled_at DATETIME(6) NULL,
  courier_name VARCHAR(50) NULL,
  tracking_number VARCHAR(64) NULL,
  shipped_at DATETIME(6) NULL,
  delivered_at DATETIME(6) NULL,
  confirmed_at DATETIME(6) NULL,
  canceled_at DATETIME(6) NULL,
  cancel_reason_label VARCHAR(100) NULL,
  cancel_detail VARCHAR(500) NULL,
  buyer_visible TINYINT(1) NOT NULL DEFAULT 1,
  seller_visible TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME(6) NOT NULL,
  updated_at DATETIME(6) NOT NULL,
  PRIMARY KEY (trade_uuid),
  KEY ix_trade_card_buyer (buyer_uuid, buyer_visible, list_bucket, created_at),
  KEY ix_trade_card_seller (seller_uuid, seller_visible, list_bucket, created_at),
  KEY ix_trade_card_phase (phase, created_at),
  CONSTRAINT ck_trade_card_bucket CHECK (list_bucket IN ('IN_PROGRESS', 'CONFIRMED', 'CANCELED'))
) COMMENT='내역 화면용 거래 카드. 수락 대기만 있는 거래는 이 표에 없다';

CREATE TABLE processed_event (
  event_id CHAR(36) NOT NULL,
  event_type VARCHAR(80) NOT NULL,
  processed_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (event_id)
) COMMENT='trade_query 멱등 키';
