#!/usr/bin/env python3
"""
Script para generar iconos de aplicación en todos los tamaños necesarios
para Android e iOS usando el logo actual.
"""

import os
from PIL import Image, ImageOps
import sys

def ensure_dir(directory):
    """Crear directorio si no existe"""
    if not os.path.exists(directory):
        os.makedirs(directory)

def resize_image(input_path, output_path, size, maintain_aspect=True):
    """Redimensionar imagen manteniendo calidad"""
    try:
        with Image.open(input_path) as img:
            # Convertir a RGBA si no lo está
            if img.mode != 'RGBA':
                img = img.convert('RGBA')
            
            if maintain_aspect:
                # Mantener aspecto y centrar en un cuadrado
                img.thumbnail((size, size), Image.Resampling.LANCZOS)
                # Crear una imagen cuadrada con fondo transparente
                new_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
                # Centrar la imagen
                x = (size - img.width) // 2
                y = (size - img.height) // 2
                new_img.paste(img, (x, y), img)
                img = new_img
            else:
                # Redimensionar directamente
                img = img.resize((size, size), Image.Resampling.LANCZOS)
            
            # Guardar como PNG
            img.save(output_path, 'PNG', optimize=True)
            print(f"✓ Generado: {output_path} ({size}x{size})")
            return True
    except Exception as e:
        print(f"✗ Error generando {output_path}: {e}")
        return False

def generate_android_icons(logo_path):
    """Generar iconos para Android"""
    print("\n🤖 Generando iconos para Android...")
    
    android_sizes = {
        'mipmap-mdpi': 48,
        'mipmap-hdpi': 72,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    base_path = "android/app/src/main/res"
    success_count = 0
    
    for folder, size in android_sizes.items():
        folder_path = os.path.join(base_path, folder)
        ensure_dir(folder_path)
        
        output_path = os.path.join(folder_path, "ic_launcher.png")
        if resize_image(logo_path, output_path, size):
            success_count += 1
    
    print(f"✓ Android: {success_count}/{len(android_sizes)} iconos generados")
    return success_count == len(android_sizes)

def generate_ios_icons(logo_path):
    """Generar iconos para iOS"""
    print("\n🍎 Generando iconos para iOS...")
    
    # Definir todos los tamaños necesarios para iOS
    ios_icons = [
        ("Icon-App-20x20@1x.png", 20),
        ("Icon-App-20x20@2x.png", 40),
        ("Icon-App-20x20@3x.png", 60),
        ("Icon-App-29x29@1x.png", 29),
        ("Icon-App-29x29@2x.png", 58),
        ("Icon-App-29x29@3x.png", 87),
        ("Icon-App-40x40@1x.png", 40),
        ("Icon-App-40x40@2x.png", 80),
        ("Icon-App-40x40@3x.png", 120),
        ("Icon-App-60x60@2x.png", 120),
        ("Icon-App-60x60@3x.png", 180),
        ("Icon-App-76x76@1x.png", 76),
        ("Icon-App-76x76@2x.png", 152),
        ("Icon-App-83.5x83.5@2x.png", 167),
        ("Icon-App-1024x1024@1x.png", 1024)
    ]
    
    base_path = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ensure_dir(base_path)
    
    success_count = 0
    
    for filename, size in ios_icons:
        output_path = os.path.join(base_path, filename)
        if resize_image(logo_path, output_path, size):
            success_count += 1
    
    print(f"✓ iOS: {success_count}/{len(ios_icons)} iconos generados")
    return success_count == len(ios_icons)

def main():
    """Función principal"""
    print("🚀 Generador de Iconos de Aplicación")
    print("=" * 50)
    
    # Verificar que el logo existe
    logo_path = "assets/images/logo.png"
    if not os.path.exists(logo_path):
        print(f"❌ Error: No se encontró el logo en {logo_path}")
        sys.exit(1)
    
    print(f"📱 Usando logo: {logo_path}")
    
    # Generar iconos para Android
    android_success = generate_android_icons(logo_path)
    
    # Generar iconos para iOS
    ios_success = generate_ios_icons(logo_path)
    
    # Resumen final
    print("\n" + "=" * 50)
    if android_success and ios_success:
        print("🎉 ¡Todos los iconos se generaron exitosamente!")
        print("✓ Android: Completo")
        print("✓ iOS: Completo")
    else:
        print("⚠️  Algunos iconos no se pudieron generar:")
        print(f"Android: {'✓' if android_success else '✗'}")
        print(f"iOS: {'✓' if ios_success else '✗'}")
    
    print("\n💡 Recuerda hacer 'flutter clean' y 'flutter pub get' después de cambiar los iconos.")

if __name__ == "__main__":
    main()