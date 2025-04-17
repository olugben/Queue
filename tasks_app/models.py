from django.db import models

# Create your models here.
from django.db import models
from django.contrib.auth.models import AbstractUser

class User(AbstractUser):
    company = models.CharField(max_length=100, blank=True)

class Task(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    email = models.EmailField()
    message = models.TextField()
    created_at = models.DateTimeField(auto_now_add=True)
    status = models.CharField(max_length=20, default='pending')
    celery_task_id = models.CharField(max_length=255, blank=True, null=True)
    completed_at = models.DateTimeField(null=True, blank=True)  #


