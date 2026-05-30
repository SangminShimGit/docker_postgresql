FROM postgres:15-alpine
# 초기화 스크립트를 이미지 내부로 복사
COPY ./init/01_init.sql /docker-entrypoint-initdb.d/