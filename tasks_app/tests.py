import time
from rest_framework.test import APITestCase
from rest_framework import status
from tasks_app.models import User, Task
from django.urls import reverse
from unittest.mock import patch
from celery.result import AsyncResult

class TaskAPITestCase(APITestCase):

    def setUp(self):
        # Create a user with email, username, and password
        self.user = User.objects.create_user(
            email='test@example.com',
            username='testuser',
            password='testpass123'
        )

    @patch('tasks_app.views.process_task.delay')  # Mock Celery task
    @patch('celery.result.AsyncResult')  # Mock Celery AsyncResult
    def test_process_task_view(self, mock_async_result, mock_task):
        # URL for the process task view
        url = reverse('process-task')  # Make sure this is the correct view name
        data = {
            'email': 'test@example.com',  # Updated field
            'message': 'This is a test task'
        }

        # Authenticate the user
        self.client.force_authenticate(user=self.user)

        # Mock Celery task call to avoid actual task execution
        mock_task.return_value.id = 'dummy_task_id'

        # Make the authenticated POST request
        response = self.client.post(url, data)

        # Check if the response status is HTTP_202_ACCEPTED
        self.assertEqual(response.status_code, status.HTTP_202_ACCEPTED)

        # Check if Celery task was called
        mock_task.assert_called_once()

    @patch('celery.result.AsyncResult')  # Mock Celery AsyncResult
    def test_task_status_view(self, mock_async_result):
        # Create a task and set a Celery task ID
        task = Task.objects.create(
            user=self.user,
            email='test@example.com',
            message='This is a test task',
            celery_task_id='dummy_task_id',  # Mock Celery task ID
            status='PENDING'  # Initially PENDING
        )

        # Mock the Celery result status as PENDING initially
        mock_async_result.return_value.status = 'PENDING'

        # URL for task status view
        url = reverse('task-status', kwargs={'task_id': task.id})  

        # Authenticate the user
        self.client.force_authenticate(user=self.user)

        # Make the authenticated GET request to check initial status
        response = self.client.get(url)

        # Check if the response status is HTTP_200_OK
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # Check if the task status is PENDING at the first request
        self.assertEqual(response.data['celery_status'], 'PENDING')


    
