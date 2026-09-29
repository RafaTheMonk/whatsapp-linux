#!/usr/bin/env python3
"""Gera os icones da bandeja com o contador de nao lidas.

O processo principal do Electron nao tem canvas nem fonte, entao os icones com
numero saem prontos daqui e vao versionados em build/. Mesmo visual do modo
tray (src/whatsapp-tray.py): circulo vermelho no quarto superior direito, numero
branco em negrito, "9+" acima de 9. Tambem gera o icone cinza do app suspenso.

So precisa rodar para mudar os icones. Requer Pillow (pacote python-pillow no
Arch, python3-pil no Debian); quem roda o app nao precisa de nada disso.

    python3 electron/scripts/gerar-icones-bandeja.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

BUILD = Path(__file__).resolve().parent.parent / "build"
VERMELHO = (229, 57, 53, 255)  # #e53935, o mesmo do modo tray
ROTULOS = [str(n) for n in range(1, 10)] + ["9+"]


def base(tamanho: int) -> Image.Image:
    # A 1x e o proprio tray.png; a 2x sai do icone grande, que tem detalhe.
    if tamanho == 22:
        return Image.open(BUILD / "tray.png").convert("RGBA")
    return Image.open(BUILD / "icon.png").convert("RGBA").resize((tamanho, tamanho), Image.LANCZOS)


def com_marca(img: Image.Image, rotulo: str) -> Image.Image:
    # Desenha em 4x e reduz: sem isso o circulo sai serrilhado a 22 px.
    escala = 4
    lado = img.width * escala
    camada = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
    d = ImageDraw.Draw(camada)
    diametro = int(lado * (0.62 if len(rotulo) > 1 else 0.56))
    x0, y0 = lado - diametro, 0
    d.ellipse((x0, y0, lado - 1, diametro - 1), fill=VERMELHO)
    fonte = ImageFont.load_default(size=int(diametro * (0.62 if len(rotulo) > 1 else 0.78)))
    d.text((x0 + diametro / 2, y0 + diametro / 2), rotulo, font=fonte, fill="white",
           anchor="mm", stroke_width=max(1, diametro // 28), stroke_fill="white")
    marca = camada.resize(img.size, Image.LANCZOS)
    return Image.alpha_composite(img, marca)


def cinza(img: Image.Image) -> Image.Image:
    # Tons de cinza mantendo a transparencia, e mais apagado, para ler como inativo.
    alfa = img.getchannel("A")
    g = img.convert("L").point(lambda v: 90 + v * 0.45).convert("RGBA")
    g.putalpha(alfa)
    return g


def nome(rotulo: str | None, sufixo: str) -> str:
    if rotulo is None:
        return f"tray{sufixo}.png"
    return f"tray-{rotulo.replace('+', 'mais')}{sufixo}.png"


def main() -> None:
    for tamanho, sufixo in ((22, ""), (44, "@2x")):
        b = base(tamanho)
        if sufixo:
            b.save(BUILD / nome(None, sufixo))
        for rotulo in ROTULOS:
            com_marca(b, rotulo).save(BUILD / nome(rotulo, sufixo))
        cinza(b).save(BUILD / f"tray-suspenso{sufixo}.png")
    print("icones gerados em", BUILD)


if __name__ == "__main__":
    main()
