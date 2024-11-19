FROM golang:1.22 as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download
COPY . .

ENV CGO_ENABLED=0 GOOS=linux GOARCH=amd64
RUN go build -tags lambda.norpc -o main ./cmd/main.go

FROM public.ecr.aws/lambda/provided:al2023

COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.1 /lambda-adapter /opt/extensions/lambda-adapter
COPY --from=builder /app/main ./main

ENTRYPOINT ["./main"]
