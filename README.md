🐋 GitHub, Docker Hub, PostgreSQL 연동 및 로컬 구동 전체 가이드
본 가이드는 개인 GitHub 저장소 생성부터 Docker Hub 연동, 그리고 PostgreSQL에 간단한 테이블과 스토어드 프로시저(SP)를 포함한 개발 초기 버전 세팅 과정을 단계별로 다룹니다.

전체적인 흐름은 [GitHub 소스 관리] ➡️ [Docker 빌드 및 Hub 푸시] ➡️ [로컬에서 실행 및 검증] 순서로 진행됩니다.

📂 1. 프로젝트 디렉토리 구조 설정
로컬 PC에 작업할 폴더를 하나 만들고, 다음과 같이 파일 구조를 구성합니다.

Plaintext
my-postgres-project/
├── init/
│   └── 01_init.sql           # 테이블 및 SP 초기화 스크립트
├── .gitignore
├── README.md
├── Dockerfile                # Docker Hub 빌드용 정의 파일
└── docker-compose.yml        # 로컬 컨테이너 구동용 정의 파일
📝 2. 초기 데이터베이스 스크립트 작성 (init/01_init.sql)
PostgreSQL 공식 도커 이미지는 /docker-entrypoint-initdb.d/ 폴더에 .sql 파일을 넣어두면, 컨테이너가 최초 실행될 때 자동으로 실행해 줍니다. 회원 테이블과 회원을 추가하는 간단한 스토어드 프로시저(SP)를 작성합니다.

SQL
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
🛠️ 3. 로컬 구동 및 빌드를 위한 파일 설정
3-1. docker-compose.yml 작성
매번 도커 명령어를 길게 입력하지 않도록 정의 파일을 생성합니다. 초기화 스크립트 폴더와 데이터 영속성을 위한 볼륨 설정을 연결합니다.

YAML
version: '3.8'

services:
  db:
    image: postgres:15-alpine
    container_name: my_postgres_db
    restart: always
    environment:
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      # 초기화 스크립트 볼륨 매핑
      - ./init:/docker-entrypoint-initdb.d
      # 데이터 영속성을 위한 저장 공간 지정
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
3-2. Dockerfile 작성 (프로젝트 루트 경로)
초기 세팅(SQL 스크립트)을 포함한 나만의 커스텀 이미지를 만들기 위해 사용합니다.

Dockerfile
FROM postgres:15-alpine
# 초기화 스크립트를 이미지 내부의 자동 실행 경로로 복사
COPY ./init/01_init.sql /docker-entrypoint-initdb.d/
🚀 4. 전체 CLI 명령어 요약집
각 단계별 터미널(Git Bash, PowerShell 등) 실행 명령어입니다.

4-1. GitHub 소스 코드 관리 및 커밋
로컬 프로젝트 폴더를 Git 저장소로 초기화하고 원격 저장소에 푸시합니다.

Bash
# 현재 폴더를 Git 저장소로 초기화
git init

# 변경된 모든 파일 추가
git add .

# 첫 번째 커밋 메시지 작성
git commit -m "feat: 초기 PostgreSQL 도커 환경 및 SP 추가"

# 기본 브랜치 이름을 main으로 변경
git branch -M main

# 내 원격 GitHub 저장소 연결
git remote add origin [https://github.com/charlieshim/my-postgres-project.git](https://github.com/charlieshim/my-postgres-project.git)

# GitHub 원격 저장소로 원본 소스 푸시
git push -u origin main
4-2. Docker Hub 로그인 및 이미지 빌드/푸시
내 실제 도커 허브 ID인 charlieshim을 사용하여 인증 후 이미지를 생성하고 업로드합니다. 도커 허브는 웹에서 레포지토리를 미리 만들지 않아도, 내 ID를 붙여 푸시하면 자동 생성됩니다.

Bash
# 1. 도커 허브 인증 로그인 (Username과 Password 입력)
docker login

# 2. 내 계정 ID를 네임스페이스로 지정하여 이미지 빌드 (맨 끝에 점 '.' 필수)
docker build -t charlieshim/my-postgres-db:1.0 .

# 3. 도커 허브로 이미지 푸시
docker push charlieshim/my-postgres-db:1.0
💡 로그인 오류(인증 실패/Access Denied) 발생 시 대안:
2차 인증(2FA) 등으로 로그인이 막힐 경우, Docker Hub 웹사이트 Account Settings ➡️ Security에서 발급받은 액세스 토큰 문자열을 복사하여 비밀번호 칸에 입력합니다.

Bash
docker login -u charlieshim
4-3. Docker 컨테이너 구동 (로컬 실행)
도커 허브에 업로드한 나만의 이미지를 기반으로 로컬에서 컨테이너를 구동합니다. 명령어 가독성을 위해 줄바꿈 기호를 사용할 때, 운영체제별 터미널 환경에 맞춰 실행해 주세요.

리눅스 / 맥 (macOS) / Git Bash 환경 (백슬래시 \ 사용):

Bash
docker run -d \
  --name my_local_db \
  -p 5432:5432 \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=mydb \
  charlieshim/my-postgres-db:1.0
윈도우 PowerShell 환경 (백틱 ` 사용):

PowerShell
docker run -d `
  --name my_local_db `
  -p 5432:5432 `
  -e POSTGRES_USER=myuser `
  -e POSTGRES_PASSWORD=mypassword `
  -e POSTGRES_DB=mydb `
  charlieshim/my-postgres-db:1.0
한 줄로 이어서 실행할 때 (줄바꿈 기호 없음):

Bash
docker run -d --name my_local_db -p 5432:5432 -e POSTGRES_USER=myuser -e POSTGRES_PASSWORD=mypassword -e POSTGRES_DB=mydb charlieshim/my-postgres-db:1.0
4-4. 데이터베이스 및 스토어드 프로시저(SP) 검증
컨테이너 내부 psql 시스템에 접속하여 스크립트가 정상 반영되었는지 확인합니다.

Bash
# 1. 실행 중인 PostgreSQL 컨테이너 내부의 psql 접속
docker exec -it my_local_db psql -U myuser -d mydb

# psql 접속 후 아래 쿼리들을 한 줄씩 실행합니다:

# 2. 초기 데이터가 테이블(users)에 정상 입력되었는지 조회
SELECT * FROM users;

# 3. 작성해 둔 스토어드 프로시저(SP) 호출하여 새 유저 추가
CALL insert_user('new_github_user', 'git@example.com');

# 4. 데이터 정상 반영 재확인
SELECT * FROM users;

# 5. psql 종료 및 빠져나오기
\q
💡 핵심 개념 및 주의점 요약
데이터 영속성 관리를 위한 볼륨(Volume) 원리
도커 컨테이너는 기본적으로 일회성 구조이므로 컨테이너를 삭제하면 내부 데이터도 함께 지워집니다. 가이드의 - pgdata:/var/lib/postgresql/data 볼륨 옵션은 컨테이너 내 데이터 폴더를 로컬 하드디스크 독립 저장 공간에 실시간 동기화하여 보존해 줍니다.


주의: 초기화 SQL 스크립트는 매핑된 로컬 볼륨 폴더가 완전히 비어있을 때(최초 구동 시)만 실행됩니다. 기존 데이터 볼륨이 남아 있다면 스크립트는 실행되지 않고 기존 데이터가 우선 구동됩니다.

로컬 개발 디비(Local DB)와 원격 개발 디비(Dev DB)의 차이
현재 세팅된 환경은 철저히 내 컴퓨터 내부(Localhost)에서 나 혼자 빠르게 테스트하기 위한 샌드박스 목적의 로컬 디비입니다.
추후 팀원들과 공유하는 '원격 개발 디비'로 발전시키려면 AWS EC2나 RDS 같은 클라우드 인프라로 마이그레이션해야 하며, 비밀번호 강화 및 특정 IP만 접근 허용하는 방화벽(Security Group) 설정 등의 추가 보안 작업이 필수적입니다.