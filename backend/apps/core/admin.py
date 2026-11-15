"""Administración de Django para el núcleo del sistema."""

from django.contrib import admin

from backend.apps.core.models import Local, Usuario


@admin.register(Local)
class LocalAdmin(admin.ModelAdmin):
    list_display = ("codigo", "nombre", "telefono", "activo", "creado_en")
    list_filter = ("activo",)
    search_fields = ("codigo", "nombre")


@admin.register(Usuario)
class UsuarioAdmin(admin.ModelAdmin):
    list_display = (
        "nombre_usuario",
        "correo",
        "rol",
        "local",
        "es_global",
        "activo",
        "creado_en",
    )
    list_filter = ("rol", "es_global", "activo", "local")
    search_fields = ("nombre_usuario", "correo", "nombre", "apellido")

