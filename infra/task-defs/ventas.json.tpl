{
  "family": "${PROJECT}-ventas",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${BACKEND_CPU}",
  "memory": "${BACKEND_MEM}",
  "executionRoleArn": "${LABROLE}",
  "taskRoleArn": "${LABROLE}",
  "containerDefinitions": [
    {
      "name": "ventas",
      "image": "${ECR_REGISTRY}/${ECR_NAMESPACE}/ventas:${IMAGE_TAG}",
      "essential": true,
      "portMappings": [{ "containerPort": 8080, "protocol": "tcp" }],
      "environment": [
        { "name": "DB_ENDPOINT", "value": "${RDS_ENDPOINT}" },
        { "name": "DB_PORT", "value": "3306" },
        { "name": "DB_NAME", "value": "${DB_NAME}" },
        { "name": "DB_USERNAME", "value": "${DB_MASTER_USER}" },
        { "name": "CORS_ALLOWED_ORIGINS", "value": "http://${ALB_DNS}" }
      ],
      "secrets": [
        { "name": "DB_PASSWORD", "valueFrom": "${SECRET_PW_ARN}" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${LOG_GROUP}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "ventas"
        }
      }
    }
  ]
}
