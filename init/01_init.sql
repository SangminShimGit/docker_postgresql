-- 1. 테이블 생성
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. 간단한 스토어드 프로시저(SP) 생성
CREATE OR REPLACE PROCEDURE insert_user(
    p_username VARCHAR,
    p_email VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO users (username, email)
    VALUES (p_username, p_email);
END;
$$;

-- 3. 초기 테스트 데이터 삽입
CALL insert_user('docker_user', 'docker@example.com');