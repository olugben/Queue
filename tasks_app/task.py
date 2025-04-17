# from celery import shared_task
# from time import sleep
# from .models import Task

# @shared_task
# def process_task(task_id):
#     task = Task.objects.get(id=task_id)
#     task.status = 'processing'
#     task.save()
    
#     # Simulate long-running task
#     sleep(30)
    
#     task.status = 'completed'
#     task.save()
#     return f"Processed task {task_id}"
from django.utils import timezone

from celery import current_task
from celery.states import STARTED, SUCCESS, FAILURE
from celery.exceptions import Ignore
from tasks_app.models import Task  # Adjust the import based on your actual model
from time import sleep
from celery import shared_task

from django.db import transaction
from tasks_app.models import Task

@shared_task(bind=True)
def process_task(self, task_id):
    try:
        task = Task.objects.get(id=task_id)

        # Optional: update status to processing
        task.status = 'processing'
        task.save(update_fields=['status'])

        # Simulate processing
        sleep(30)

        # Mark task as completed
        task.status = 'completed'
        task.completed_at = timezone.now()
        task.save(update_fields=['status', 'completed_at'])

        return {"success": True, "task_id": task_id}

    except Task.DoesNotExist:
        raise

    except Exception as e:
        Task.objects.filter(id=task_id).update(status='failed')
        raise
