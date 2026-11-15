"""Pruebas del módulo núcleo e identidad."""

from django.test import TestCase

from backend.apps.core.models import Local, Usuario


class CoreModelsTest(TestCase):
    def test_crear_local(self):
        local = Local.objects.create(codigo="L01", nombre="Local Principal")
        self.assertEqual(str(local), "L01 - Local Principal")

    def test_crear_usuario(self):
        user = Usuario.objects.create_user(
            nombre_usuario="testuser",
            correo="test@example.com",
            password="securepassword",
        )
        self.assertTrue(user.check_password("securepassword"))
        self.assertTrue(user.is_active)
        self.assertFalse(user.is_staff)
