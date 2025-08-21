CREATE DATABASE IF NOT EXISTS gpt_app CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gpt_app;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id VARCHAR(50) UNIQUE NOT NULL,
  user_name VARCHAR(50) NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE emotion_diary (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_pk INT NOT NULL,
  mood VARCHAR(50),
  notes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
                        ON UPDATE CURRENT_TIMESTAMP,
  deleted_at DATETIME NULL,
  CONSTRAINT fk_emotion_diary_user
    FOREIGN KEY (user_pk) REFERENCES users(id)
    ON DELETE CASCADE
);

CREATE INDEX idx_diary_user_created ON emotion_diary(user_pk, created_at);
