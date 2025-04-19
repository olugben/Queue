from django.urls import path
from .views import ProcessTaskView, TaskStatusView, public_health_check

urlpatterns = [
    path('process/', ProcessTaskView.as_view(), name='process-task'),
    path('status/<str:task_id>/', TaskStatusView.as_view(), name='task-status'),
    path('public-health-check/', public_health_check, name='public-health-check'),
]