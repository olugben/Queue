from django.shortcuts import render
from rest_framework.permissions import IsAuthenticated
from celery.result import AsyncResult
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .task import process_task
# Create your views here.
from rest_framework import generics, status
from rest_framework.response import Response


from .models import User, Task
from .serializers import UserSerializer, TaskSerializer

from django.http import Http404
from rest_framework.response import Response
from rest_framework import status
from celery.result import AsyncResult
from .models import Task  


from django.http import JsonResponse
from rest_framework.decorators import api_view

@api_view(['GET'])
def public_health_check(request):
    return JsonResponse({'status': 'ok'}, status=200)

class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = UserSerializer




class ProcessTaskView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        serializer = TaskSerializer(data=request.data)
        if serializer.is_valid():
            #Save initial task to DB with status "pending"
            task = serializer.save(user=request.user)

            #  Call Celery task
            async_result = process_task.delay(task.id)

            #  Update the DB with Celery task ID and status
            task.celery_task_id = async_result.id
            task.status = 'queued'  
            task.save()

            return Response({'task_id': task.id}, status=status.HTTP_202_ACCEPTED)

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)




class TaskStatusView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, task_id):
        try:
            # Fetch from DB
            db_task = Task.objects.get(id=task_id, user=request.user)
            print(db_task.status, "db_task")
            #  Fetch Celery status and result
            celery_task = AsyncResult(db_task.celery_task_id)  # Use Celery task ID
            celery_status = celery_task.status
            celery_result = celery_task.result if celery_task.ready() else None
            
            response_data = {
                'task_id': db_task.id,
                'db_status': db_task.status,
                'celery_status': celery_status,
                
                'message': db_task.message,
                'created_at': db_task.created_at,
            }
            
            
            return Response(response_data)

        except Task.DoesNotExist:
            return Response({'error': 'Task not found in database'}, status=status.HTTP_404_NOT_FOUND)