# Multiplatform build


docker login -u carlkuhligk
docker buildx create --name securitytracker
docker buildx use securitytracker
docker buildx inspect --bootstrap

docker buildx build --tag carlkuhligk/securitymotiontracker:debug --platform=linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8 --push .


docker-compose --env-file db.env up -d
