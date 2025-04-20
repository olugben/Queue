# Django Microservice with Celery, Redis, Docker & AWS 



---

##  Overview



Overview
This project is a Django-based microservice that provides a REST API for processing background tasks using Celery and Redis. The application is containerized with Docker and includes infrastructure as code for AWS deployment.
A Django + DRF microservice exposing:
- **GET** `/api/public-health-check/` — returns the health of our application (the health check endpoint).
-  **POST** `/api/register/` — accepts `{ "username": "...", "password": "...", "email": "..." } -registration of our application
-  **POST** `/api/token/` — accepts `{ "username": "...", "password": "...", "email": "..." } -login endpoint 
- **POST** `/api/process/` — accepts `{ "email": "...", "message": "..." }`, enqueues a Celery task via Redis.  
- **GET** `/api/status/<task_id>/` — returns task status and result.

Containerized (web, Redis, Celery, Postgres), deployed to AWS EC2 via Terraform, CI/CD via GitHub Actions.

---

## Project Structure

