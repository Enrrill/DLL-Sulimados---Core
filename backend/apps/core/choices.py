"""Enumeraciones y choices para el núcleo del sistema."""

from django.db import models


class RolUsuario(models.TextChoices):
    ADMINISTRADOR = "admin", "Administrador"
    GERENTE = "gerente", "Gerente de local"
    OPERARIO = "operario", "Operario de producción"
    VENDEDOR = "vendedor", "Vendedor / Cajero"

