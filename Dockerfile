# 阶段一：构建前端
FROM node:18-alpine AS frontend-builder
WORKDIR /app/ruoyi-ui
COPY ruoyi-ui/package*.json ./
RUN npm install --registry=https://registry.npmmirror.com
COPY ruoyi-ui/ ./
RUN npm run build:prod

# 阶段二：构建后端
FROM maven:3.8.6-eclipse-temurin-11 AS backend-builder
WORKDIR /app/ruoyi-admin
COPY ruoyi-admin/pom.xml ./
COPY ruoyi-admin/src ./src
RUN mvn clean package -DskipTests

# 阶段三：生产镜像
FROM eclipse-temurin:11-jre
WORKDIR /app

# 复制后端 JAR
COPY --from=backend-builder /app/ruoyi-admin/target/*.jar app.jar

# 复制前端静态文件
COPY --from=frontend-builder /app/ruoyi-ui/dist /app/static

# 设置环境变量（可通过外部传入覆盖）
ENV SPRING_PROFILES_ACTIVE=prod
ENV SPRING_DATASOURCE_URL=jdbc:mysql://localhost:3306/ry-vue?useUnicode=true&characterEncoding=utf8&zeroDateTimeBehavior=convertToNull&useSSL=true&serverTimezone=Asia/Shanghai
ENV SPRING_DATASOURCE_USERNAME=ruoyi
ENV SPRING_DATASOURCE_PASSWORD=ruoyi

# 暴露端口
EXPOSE 8080

# 启动命令
CMD ["java", "-jar", "app.jar"]