# Documentação do Desafio de Infraestrutura e Deployment

## Introdução
Este documento detalha a solução implementada para o desafio, abordando desde a containerização da aplicação até a automação do deployment no AWS Kubernetes (EKS), utilizando AWS CodePipeline, Terraform e Helm.

## Estrutura do Projeto
O repositório da app foi organizado da seguinte forma:
```
├── docker/ # Dockerfile para containerização 
├── helm/ # Helm chart para deploy da aplicação 
├── app/ # Código-fonte da aplicação Java com Spring Boot
└── pipeline/ # Definição do AWS CodePipeline

```

## Repositório da aplicação
O repositório da aplicação está disponível no seguinte repositório:
[sre-challenge](https://github.com/adriell/sre-challenge)

## Resumo da solução

### 1. Containerização da Aplicação
A aplicação foi empacotada em um container utilizando Docker. O Dockerfile está localizado na pasta `docker/` e possui a seguinte estrutura:

```Dockerfile
FROM public.ecr.aws/docker/library/maven:3.9.9-amazoncorretto-23 AS builder

WORKDIR /app

COPY . .

RUN mvn clean package -DskipTests

FROM public.ecr.aws/docker/library/maven:3.9.9-amazoncorretto-23-alpine

RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

WORKDIR /app

COPY --from=builder /app/target/*.jar app.jar

EXPOSE 8080

CMD ["java", "-Djava.net.preferIPv4Stack=true", "-jar", "app.jar"]
```
### 2. Helm Chart
Foi criado um Helm Chart para facilitar o deploy da aplicação no Kubernetes. O Helm Chart inclui no values.yaml:
```sh
# values.yaml

replicaCount: 2

image:
  repository: 674622770595.dkr.ecr.us-east-1.amazonaws.com/sre-challenge
  pullPolicy: IfNotPresent
  tag: "latest"

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/scheme: "internal"
    alb.ingress.kubernetes.io/target-type: "ip"
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "61"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "60"
    alb.ingress.kubernetes.io/success-codes: "200-299"
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}]'
    alb.ingress.kubernetes.io/load-balancer-attributes: "idle_timeout.timeout_seconds=60"
    alb.ingress.kubernetes.io/subnets: "subnet-043be10d9c45a7b00, subnet-0e8b00c66b770a0f0"
    alb.ingress.kubernetes.io/security-groups: "sg-0d767ea4ef8151def"
  hosts:
    - host: 
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: sre-challenge-app-service
              port:
                number: 8080

resources:
  limits:
    cpu: 500m
    memory: 512Mi
  requests:
    cpu: 250m
    memory: 256Mi

env: []

strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1

hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  cpuUtilization: 70  # Escala quando CPU passar de 70%
  memoryUtilization: 80 
```
### 3. Integração com AWS CodeCommit e GitHub
Foi criado um repositório no AWS CodeCommit e configuramos o mirroring com o GitHub. A configuração foi feita utilizando os seguintes comandos:
```sh
git push --mirror ssh://git-codecommit.us-east-1.amazonaws.com/v1/repos/sre-challenge-app
```

### 4. Pipeline de Deployment com AWS CodePipeline
A pipeline no AWS CodePipeline foi configurada com os seguintes steps:

* Clonar o repositório do CodeCommit.
* Executa o build e os tests
* Construir a imagem Docker e enviá-la para o Amazon ECR.
* Empacota a aplicação via Helm Chart e faz o deploy no cluster EKS.

Os arquivos da pipeline do codebuild está localizado na pasta `pipeline/`

### 5. Provisionamento da Infraestrutura na AWS
O Terraform foi utilizado para criar:

* VPC
* Cluster EKS

A infraestrutura foi provisionada a partir deste repositório sre-challenge-infra, garantindo modularidade e reutilização do código.
### 6. Alerta no AWS CloudWatch (Tarefa Bônus)
Criei um evento no AWS CloudWatch que detecta falhas na execução da AWS CodePipeline e envia uma notificação via Amazon SNS. A regra foi configurada para monitorar o status da pipeline e acionar o SNS em caso de falha.

```sh
AWSTemplateFormatVersion: '2010-09-09'
Description: CloudFormation template for EventBridge Rulesre-challenge-CodePipelineEvent
Resources:
  Ruleb9dc8911:
    Type: AWS::Events::Rule
    Properties:
      Name: sre-challenge-CodePipelineEvent
      EventPattern: >-
        {"source":["aws.codepipeline"],"detail-type":["CodePipeline Pipeline
        Execution State Change"],"detail":{"state":["FAILED"]}}
      State: ENABLED
      EventBusName: default
      Targets:
        - Id: Id54764b87-f5a5-4c8d-8be4-10f5bffadb1b
          Arn:
            Fn::Sub: >-
              arn:${AWS::Partition}:sns:${AWS::Region}:${AWS::AccountId}:sre-challenge-CodePipelineFailureTopic
          RoleArn: >-
            arn:aws:iam::674622770595:role/service-role/Amazon_EventBridge_Invoke_Sns_1615697349
Parameters: {}
```
Esse evento garante que, caso ocorra uma falha na pipeline, uma notificação seja enviada automaticamente por e-mail via SNS.

### 7. Habilitação do Actuator Health e Configuração das Probes no Deployment
A aplicação foi configurada para expor o Actuator Health, permitindo que o Kubernetes monitore a saúde da aplicação. O Actuator Health foi habilitado no Spring Boot para fornecer endpoints de saúde que podem ser utilizados para as probes.

No `application.properties` da aplicação, foi adicionada a seguinte configuração para habilitar o Actuator:

```properties
management.endpoint.health.show-details=always
management.endpoints.web.exposure.include=health,info
```
Além disso, as probes de liveness e readiness foram configuradas no Helm Chart para garantir que o Kubernetes monitore corretamente a aplicação. A configuração do deployment.yaml no Helm Chart foi atualizada com as seguintes probes:
```yaml
          readinessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
          livenessProbe:
            httpGet:
              path: /actuator/health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
            timeoutSeconds: 5
            failureThreshold: 3
```

### 8. Configuração do Horizontal Pod Autoscaler (HPA)
Para garantir a escalabilidade da aplicação, configurei o **Horizontal Pod Autoscaler** (HPA) no Kubernetes. O HPA foi configurado para ajustar automaticamente o número de réplicas da aplicação com base na utilização de CPU.

A configuração foi adicionada ao Helm Chart no arquivo `hpa.yaml`, com os seguintes parâmetros:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ .Release.Name }}
  minReplicas: {{ .Values.hpa.minReplicas }}
  maxReplicas: {{ .Values.hpa.maxReplicas }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.hpa.cpuUtilization }}
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: {{ .Values.hpa.memoryUtilization }}
```
Com essa configuração, o Kubernetes automaticamente aumenta ou diminui o número de pods em execução conforme a carga de CPU da aplicação, garantindo que ela tenha recursos suficientes durante picos de tráfego e não consuma recursos excessivos durante períodos de baixa demanda.



