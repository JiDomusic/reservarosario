#!/usr/bin/env python3
"""
Script para crear iconos de SODITA usando PIL (Python Imaging Library)
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import os
    
    def create_sodita_icon(size):
        """Crear un icono de SODITA del tamaño especificado"""
        # Crear imagen con fondo transparente
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Colores
        orange = (248, 103, 4)  # #F86704
        green = (76, 175, 80)   # #4CAF50
        yellow = (255, 193, 7)  # #FFC107
        white = (255, 255, 255)
        
        # Fondo circular naranja
        margin = size * 0.05
        circle_size = size - 2 * margin
        draw.ellipse([margin, margin, margin + circle_size, margin + circle_size], 
                    fill=orange, outline=(230, 81, 0), width=max(1, size//64))
        
        # Botella (rectángulo redondeado)
        bottle_width = size * 0.3
        bottle_height = size * 0.6
        bottle_x = (size - bottle_width) / 2
        bottle_y = size * 0.25
        
        # Cuerpo de la botella
        draw.rounded_rectangle([bottle_x, bottle_y, bottle_x + bottle_width, bottle_y + bottle_height],
                             radius=size//20, fill=green, outline=(46, 125, 50), width=max(1, size//128))
        
        # Cuello de la botella
        neck_width = bottle_width * 0.4
        neck_height = size * 0.15
        neck_x = (size - neck_width) / 2
        neck_y = bottle_y - neck_height
        draw.rectangle([neck_x, neck_y, neck_x + neck_width, bottle_y], 
                      fill=green, outline=(46, 125, 50))
        
        # Tapa
        cap_width = neck_width * 1.2
        cap_height = size * 0.08
        cap_x = (size - cap_width) / 2
        cap_y = neck_y - cap_height/2
        draw.rounded_rectangle([cap_x, cap_y, cap_x + cap_width, cap_y + cap_height],
                             radius=size//40, fill=yellow, outline=(245, 127, 23), width=max(1, size//128))
        
        # Etiqueta en la botella
        label_width = bottle_width * 0.8
        label_height = size * 0.15
        label_x = (size - label_width) / 2
        label_y = bottle_y + bottle_height * 0.3
        draw.rounded_rectangle([label_x, label_y, label_x + label_width, label_y + label_height],
                             radius=size//50, fill=(255, 255, 255, 200), outline=(224, 224, 224), width=1)
        
        # Texto SODITA (solo para iconos grandes)
        if size >= 64:
            try:
                font_size = max(8, size // 20)
                # Intentar usar una fuente del sistema
                font = ImageFont.load_default()
                
                # Texto "SODITA"
                text = "SODITA"
                bbox = draw.textbbox((0, 0), text, font=font)
                text_width = bbox[2] - bbox[0]
                text_x = (size - text_width) / 2
                text_y = label_y + label_height * 0.2
                draw.text((text_x, text_y), text, fill=orange, font=font)
                
            except:
                # Si falla la fuente, dibujar un punto central
                center_x, center_y = size // 2, label_y + label_height // 2
                dot_size = max(2, size // 40)
                draw.ellipse([center_x - dot_size, center_y - dot_size, 
                            center_x + dot_size, center_y + dot_size], fill=orange)
        
        # Brillo en la botella
        highlight_x = bottle_x + bottle_width * 0.2
        highlight_y = bottle_y + bottle_height * 0.2
        highlight_width = bottle_width * 0.15
        highlight_height = bottle_height * 0.4
        draw.ellipse([highlight_x, highlight_y, highlight_x + highlight_width, highlight_y + highlight_height],
                    fill=(255, 255, 255, 100))
        
        return img
    
    def main():
        print("🍶 Creando iconos de SODITA con Python...")
        
        # Tamaños para diferentes plataformas
        sizes = {
            # Android
            'android/app/src/main/res/mipmap-mdpi/ic_launcher.png': 48,
            'android/app/src/main/res/mipmap-hdpi/ic_launcher.png': 72,
            'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png': 96,
            'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png': 144,
            'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png': 192,
            
            # Web
            'web/favicon.png': 32,
            'web/icons/Icon-192.png': 192,
            'web/icons/Icon-512.png': 512,
            'web/icons/Icon-maskable-192.png': 192,
            'web/icons/Icon-maskable-512.png': 512,
        }
        
        for path, size in sizes.items():
            try:
                # Crear directorio si no existe
                os.makedirs(os.path.dirname(path), exist_ok=True)
                
                # Crear y guardar icono
                icon = create_sodita_icon(size)
                icon.save(path, 'PNG')
                print(f"✅ Creado: {path} ({size}x{size})")
                
            except Exception as e:
                print(f"❌ Error creando {path}: {e}")
        
        # Crear icono extra grande para mostrar
        try:
            big_icon = create_sodita_icon(512)
            big_icon.save('sodita_icon_preview.png', 'PNG')
            print("🎨 Preview creado: sodita_icon_preview.png")
        except Exception as e:
            print(f"Error creando preview: {e}")
        
        print("✅ ¡Iconos de SODITA creados exitosamente!")

    if __name__ == "__main__":
        main()

except ImportError:
    print("❌ PIL (Pillow) no está instalado.")
    print("📦 Instalando Pillow...")
    import subprocess
    import sys
    
    try:
        subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
        print("✅ Pillow instalado. Ejecuta el script nuevamente.")
    except:
        print("❌ No se pudo instalar Pillow automáticamente.")
        print("💡 Ejecuta manualmente: pip install Pillow")