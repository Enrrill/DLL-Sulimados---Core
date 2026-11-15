"""Modelos de datos del núcleo e identidad del sistema.

Implementa la clase Meta con db_table explícito para cumplir con el
estándar de arquitectura del monolito modular.
"""

from django.contrib.auth.models import (
    AbstractBaseUser,
    BaseUserManager,
    PermissionsMixin,
)
from django.db import models

from backend.apps.core.choices import RolUsuario
from backend.common.base_models import ActivoMixin, TimeStampedModel


class Local(TimeStampedModel, ActivoMixin):
    """Representa cada una de las sucursales o locales del negocio."""

    codigo = models.CharField("código", max_length=10, unique=True)
    nombre = models.CharField("nombre", max_length=100)
    direccion = models.CharField("dirección", max_length=255, blank=True, default="")
    telefono = models.CharField("teléfono", max_length=50, blank=True, default="")

    class Meta:
        verbose_name = "local"
        verbose_name_plural = "locales"
        db_table = "locales"

    def __str__(self):
        return f"{self.codigo} - {self.nombre}"


class UsuarioManager(BaseUserManager):
    """Manager personalizado para el modelo Usuario."""

    def create_user(self, nombre_usuario, correo, password=None, **extra_fields):
        if not nombre_usuario:
            raise ValueError("El nombre de usuario es obligatorio")
        if not correo:
            raise ValueError("El correo electrónico es obligatorio")
        correo = self.normalize_email(correo)
        extra_fields.setdefault("activo", True)
        usuario = self.model(
            nombre_usuario=nombre_usuario, correo=correo, **extra_fields
        )
        usuario.set_password(password)
        usuario.save(using=self._db)
        return usuario

    def create_superuser(self, nombre_usuario, correo, password=None, **extra_fields):
        extra_fields.setdefault("rol", RolUsuario.ADMINISTRADOR)
        extra_fields.setdefault("is_superuser", True)
        extra_fields.setdefault("es_global", True)
        extra_fields.setdefault("activo", True)
        return self.create_user(nombre_usuario, correo, password, **extra_fields)


class Usuario(AbstractBaseUser, PermissionsMixin, TimeStampedModel, ActivoMixin):
    """Modelo de usuario centralizado para autenticación y control de acceso."""

    nombre_usuario = models.CharField(
        "nombre de usuario", max_length=150, unique=True
    )
    correo = models.EmailField("correo electrónico", max_length=254, unique=True)
    nombre = models.CharField("nombre", max_length=150, blank=True, default="")
    apellido = models.CharField("apellido", max_length=150, blank=True, default="")
    rol = models.CharField(
        "rol",
        max_length=20,
        choices=RolUsuario.choices,
        default=RolUsuario.VENDEDOR,
    )
    local = models.ForeignKey(
        Local,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="usuarios",
        verbose_name="local",
    )
    es_global = models.BooleanField("alcance global", default=False)

    objects = UsuarioManager()

    USERNAME_FIELD = "nombre_usuario"
    REQUIRED_FIELDS = ["correo"]

    @property
    def is_active(self):
        return self.activo

    @property
    def is_staff(self):
        return self.is_superuser or self.rol == RolUsuario.ADMINISTRADOR

    class Meta:
        verbose_name = "usuario"
        verbose_name_plural = "usuarios"
        db_table = "usuarios"

    def __str__(self):
        return f"{self.nombre_usuario} ({self.get_rol_display()})"
