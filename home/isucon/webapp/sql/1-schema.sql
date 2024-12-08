SET CHARACTER_SET_CLIENT = utf8mb4;
SET CHARACTER_SET_CONNECTION = utf8mb4;

USE isuride;

DROP TABLE IF EXISTS settings;
CREATE TABLE settings
(
  name  VARCHAR(30) NOT NULL COMMENT '設定名',
  value TEXT        NOT NULL COMMENT '設定値',
  PRIMARY KEY (name)
)
  COMMENT = 'システム設定テーブル';

DROP TABLE IF EXISTS chair_models;
CREATE TABLE chair_models
(
  name  VARCHAR(50) NOT NULL COMMENT '椅子モデル名',
  speed INTEGER     NOT NULL COMMENT '移動速度',
  PRIMARY KEY (name)
)
  COMMENT = '椅子モデルテーブル';

DROP TABLE IF EXISTS chairs;
CREATE TABLE chairs
(
  id           VARCHAR(26)  NOT NULL COMMENT '椅子ID',
  owner_id     VARCHAR(26)  NOT NULL COMMENT 'オーナーID',
  name         VARCHAR(30)  NOT NULL COMMENT '椅子の名前',
  model        TEXT         NOT NULL COMMENT '椅子のモデル',
  is_active    TINYINT(1)   NOT NULL COMMENT '配椅子受付中かどうか',
  access_token VARCHAR(255) NOT NULL COMMENT 'アクセストークン',
  created_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  updated_at   DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  PRIMARY KEY (id)
)
  COMMENT = '椅子情報テーブル';
ALTER TABLE chairs ADD INDEX (owner_id);
ALTER TABLE chairs ADD INDEX (access_token);

DROP TABLE IF EXISTS chair_locations;
CREATE TABLE chair_locations
(
  id         VARCHAR(26) NOT NULL,
  chair_id   VARCHAR(26) NOT NULL COMMENT '椅子ID',
  latitude   INTEGER     NOT NULL COMMENT '経度',
  longitude  INTEGER     NOT NULL COMMENT '緯度',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  PRIMARY KEY (id)
)
  COMMENT = '椅子の現在位置情報テーブル';
ALTER TABLE chair_locations ADD INDEX (chair_id, created_at);

DROP TABLE IF EXISTS users;
CREATE TABLE users
(
  id              VARCHAR(26)  NOT NULL COMMENT 'ユーザーID',
  username        VARCHAR(30)  NOT NULL COMMENT 'ユーザー名',
  firstname       VARCHAR(30)  NOT NULL COMMENT '本名(名前)',
  lastname        VARCHAR(30)  NOT NULL COMMENT '本名(名字)',
  date_of_birth   VARCHAR(30)  NOT NULL COMMENT '生年月日',
  access_token    VARCHAR(255) NOT NULL COMMENT 'アクセストークン',
  invitation_code VARCHAR(30)  NOT NULL COMMENT '招待トークン',
  created_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  updated_at      DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  PRIMARY KEY (id),
  UNIQUE (username),
  UNIQUE (access_token),
  UNIQUE (invitation_code)
)
  COMMENT = '利用者情報テーブル';

DROP TABLE IF EXISTS payment_tokens;
CREATE TABLE payment_tokens
(
  user_id    VARCHAR(26)  NOT NULL COMMENT 'ユーザーID',
  token      VARCHAR(255) NOT NULL COMMENT '決済トークン',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  PRIMARY KEY (user_id)
)
  COMMENT = '決済トークンテーブル';

DROP TABLE IF EXISTS rides;
CREATE TABLE rides
(
  id                    VARCHAR(26) NOT NULL COMMENT 'ライドID',
  user_id               VARCHAR(26) NOT NULL COMMENT 'ユーザーID',
  chair_id              VARCHAR(26) NULL     COMMENT '割り当てられた椅子ID',
  pickup_latitude       INTEGER     NOT NULL COMMENT '配車位置(経度)',
  pickup_longitude      INTEGER     NOT NULL COMMENT '配車位置(緯度)',
  destination_latitude  INTEGER     NOT NULL COMMENT '目的地(経度)',
  destination_longitude INTEGER     NOT NULL COMMENT '目的地(緯度)',
  evaluation            INTEGER     NULL     COMMENT '評価',
  created_at            DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '要求日時',
  updated_at            DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '状態更新日時',
  PRIMARY KEY (id)
)
  COMMENT = 'ライド情報テーブル';
ALTER TABLE rides ADD INDEX (chair_id, updated_at DESC);
ALTER TABLE rides ADD INDEX (chair_id, created_at DESC);
ALTER TABLE rides ADD INDEX (user_id, created_at DESC);

DROP TABLE IF EXISTS ride_statuses;
CREATE TABLE ride_statuses
(
  id              VARCHAR(26)                                                                NOT NULL,
  ride_id VARCHAR(26)                                                                        NOT NULL COMMENT 'ライドID',
  status          ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NOT NULL COMMENT '状態',
  created_at      DATETIME(6)                                                                NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '状態変更日時',
  app_sent_at     DATETIME(6)                                                                NULL COMMENT 'ユーザーへの状態通知日時',
  chair_sent_at   DATETIME(6)                                                                NULL COMMENT '椅子への状態通知日時',
  PRIMARY KEY (id)
)
  COMMENT = 'ライドステータスの変更履歴テーブル';
ALTER TABLE ride_statuses ADD INDEX (ride_id, created_at DESC);
ALTER TABLE ride_statuses ADD INDEX (ride_id, chair_sent_at, created_at);
ALTER TABLE ride_statuses ADD INDEX (ride_id, app_sent_at, created_at);


DROP TABLE IF EXISTS owners;
CREATE TABLE owners
(
  id                   VARCHAR(26)  NOT NULL COMMENT 'オーナーID',
  name                 VARCHAR(30)  NOT NULL COMMENT 'オーナー名',
  access_token         VARCHAR(255) NOT NULL COMMENT 'アクセストークン',
  chair_register_token VARCHAR(255) NOT NULL COMMENT '椅子登録トークン',
  created_at           DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '登録日時',
  updated_at           DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '更新日時',
  PRIMARY KEY (id),
  UNIQUE (name),
  UNIQUE (access_token),
  UNIQUE (chair_register_token)
)
  COMMENT = '椅子のオーナー情報テーブル';

DROP TABLE IF EXISTS coupons;
CREATE TABLE coupons
(
  user_id    VARCHAR(26)  NOT NULL COMMENT '所有しているユーザーのID',
  code       VARCHAR(255) NOT NULL COMMENT 'クーポンコード',
  discount   INTEGER      NOT NULL COMMENT '割引額',
  created_at DATETIME(6)  NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '付与日時',
  used_by    VARCHAR(26)  NULL COMMENT 'クーポンが適用されたライドのID',
  PRIMARY KEY (user_id, code)
)
  COMMENT 'クーポンテーブル';
ALTER TABLE coupons ADD INDEX (used_by);
ALTER TABLE coupons ADD INDEX (user_id, code, used_by);
ALTER TABLE coupons ADD INDEX (user_id, used_by, created_at);


ALTER TABLE chairs ADD COLUMN total_distance INTEGER NOT NULL DEFAULT 0 INVISIBLE;
ALTER TABLE chairs ADD COLUMN total_distance_updated_at DATETIME(6) INVISIBLE;
ALTER TABLE chairs ADD COLUMN last_latitude INTEGER INVISIBLE;
ALTER TABLE chairs ADD COLUMN last_longitude INTEGER INVISIBLE;
ALTER TABLE chairs ADD COLUMN last_status ENUM ('MATCHING', 'ENROUTE', 'PICKUP', 'CARRYING', 'ARRIVED', 'COMPLETED') NULL COMMENT '状態' INVISIBLE;

delimiter //

CREATE TRIGGER update_ride_statuses AFTER INSERT ON ride_statuses FOR EACH ROW BEGIN
UPDATE chairs SET last_status = NEW.status WHERE id IN (SELECT chair_id FROM rides WHERE id = NEW.ride_id);
END
//

delimiter ;
