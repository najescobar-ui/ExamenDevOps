{
  "family": "${PROJECT}-frontend",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "${FRONTEND_CPU}",
  "memory": "${FRONTEND_MEM}",
  "executionRoleArn": "${LABROLE}",
  "taskRoleArn": "${LABROLE}",
  "containerDefinitions": [
    {
      "name": "frontend",
      "image": "${ECR_REGISTRY}/${ECR_NAMESPACE}/frontend:${IMAGE_TAG}",
      "essential": true,
      "portMappings": [{ "containerPort": 80, "protocol": "tcp" }],
      "environment": [
        { "name": "VENTAS_UPSTREAM", "value": "${ALB_DNS}" },
        { "name": "DESPACHOS_UPSTREAM", "value": "${ALB_DNS}" }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${LOG_GROUP}",
          "awslogs-region": "${AWS_REGION}",
          "awslogs-stream-prefix": "frontend"
        }
      }
    }
  ]
}
