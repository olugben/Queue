# Django Microservice with Celery, Redis, Docker & AWS 



---

##  Overview



Overview
This project is a Django-based microservice that provides a REST API for processing background tasks using Celery and Redis. The application is containerized with Docker and includes infrastructure as code for AWS deployment.

The application was built to be Highly available and Scalable By using Auto Scaling group to launch new instances in response to High traffic and there is also Application Load Balancers to route traffic to healthy instances
it  expose:
- **GET** `/api/public-health-check/` — returns the health of our application (the health check endpoint).
-  **POST** `/api/register/` — accepts `{ "username": "...", "password": "...", "email": "..." } -registration of our application
-  **POST** `/api/token/` — accepts `{ "username": "...", "password": "...", "email": "..." } -login endpoint 
- **POST** `/api/process/` — accepts `{ "email": "...", "message": "..." }`, enqueues a Celery task via Redis.  
- **GET** `/api/status/<task_id>/` — returns task status and result.

Containerized (web, Redis, Celery, Postgres), deployed to AWS EC2 via Terraform, CI/CD via GitHub Actions.

---

Features
REST API endpoint to submit background tasks

Celery worker for asynchronous task processing

Redis as message broker

Task status tracking

Dockerized environment

AWS deployment ready

CI/CD pipeline integration

Prerequisites
Docker and Docker Compose

AWS account (for deployment)

Python 3.8+

Terraform 


Set up

# Clone the Dockerized Django repo:
git clone https://github.com/olugben/Queue.git
cd Queue

# Start everything:
docker-compose up --build

# In another terminal (after containers are up):
docker-compose exec web python manage.py migrate


![architecture image](Archi-diagram.png)
