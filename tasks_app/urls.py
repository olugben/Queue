from django.urls import path
from .views import ProcessTaskView, TaskStatusView

urlpatterns = [
    path('process/', ProcessTaskView.as_view(), name='process-task'),
    path('status/<str:task_id>/', TaskStatusView.as_view(), name='task-status'),
]