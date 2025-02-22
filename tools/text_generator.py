from argparse import ArgumentParser
from pathlib import Path
from typing import Dict
import sys

from PIL import Image


ATLAS_PATH = Path(__file__).parent / "prime_hud_text.png"
FONT_ATLAS = Image.open(ATLAS_PATH).convert("P")
TEXT_COORDS = {
    "A": (46, 37, 13, 15),
    "B": (1, 37, 13, 15),
    "C": (136, 35, 12, 15),
    "D": (150, 35, 12, 15),
    "E": (107, 37, 13, 15),
    "F": (164, 35, 12, 15),
    "G": (61, 48, 13, 15),
    "H": (76, 48, 13, 15),
    "I": (98, 67, 6, 15),
    "J": (122, 1, 13, 15),
    "L": (122, 35, 11, 15),
    "M": (1, 1, 19, 15),
    "N": (137, 1, 13, 15),
    "O": (152, 1, 13, 15),
    "P": (167, 1, 13, 15),
    "Q": (43, 1, 13, 17),
    "R": (182, 1, 13, 15),
    "S": (197, 1, 13, 15),
    "T": (16, 18, 13, 15),
    "U": (212, 1, 13, 15),
    "V": (227, 1, 13, 15),
    "W": (22, 1, 19, 15),
    "X": (242, 1, 13, 15),

    "a": (196, 35, 13, 13, 2),
    "b": (152, 18, 13, 15),
    "c": (211, 35, 13, 13, 2),
    "d": (167, 18, 13, 15),
    "e": (226, 35, 13, 13, 2),
    "f": (211, 65, 9, 15),
    "g": (58, 1, 13, 17, 2),
    "h": (199, 18, 13, 15),
    "i": (133, 68, 6, 13, 2),
    "k": (214, 18, 13, 15),
    "l": (118, 67, 6, 15),
    "m": (73, 1, 17, 13, 2),
    "n": (241, 35, 13, 13, 2),
    "o": (178, 50, 13, 13, 2),
    "p": (92, 1, 13, 17, 2),
    "q": (107, 1, 13, 17, 2),
    "r": (193, 50, 13, 13, 2),
    "s": (208, 50, 13, 13, 2),
    "t": (222, 65, 9, 15),
    "u": (223, 50, 13, 13, 2),
    "v": (238, 50, 13, 13, 2),
    "w": (73, 16, 17, 13, 2),
    "y": (1, 18, 13, 17, 2),
    "z": (122, 52, 13, 13, 2),

    "0": (32, 20, 13, 15),
    "1": (1, 54, 10, 15),
    "2": (47, 20, 13, 15),
    "3": (92, 20, 13, 15),
    "4": (107, 20, 13, 15),
    "5": (62, 31, 13, 15),
    "6": (77, 31, 13, 15),
    "7": (16, 35, 13, 15),
    "8": (92, 37, 13, 15),
    "9": (31, 37, 13, 15),

    " ": (0, 0, 12, 1),
    "?": (164, 52, 11, 15),
    ":": (163, 79, 5, 10, 3),
    "-": (10, 80, 10, 4, 6),
    "'": (1, 80, 7, 7),
}


glyph_cache: Dict[str, Image.Image] = {}

def get_character(character: str):
    if character in glyph_cache:
        return glyph_cache[character]

    coord = TEXT_COORDS[character]
    x, y, width, height = coord[:4]
    offset, = coord[4:5] or [0]
    glyph = FONT_ATLAS.crop((x, y, x + width, y + height))
    padded_glyph = Image.new("RGBA", (glyph.width, glyph.height + offset), (0, 0, 0, 0))
    padded_glyph.paste(glyph, (0, offset))
    padded_glyph = padded_glyph.convert("P")

    glyph_cache[character] = padded_glyph
    return padded_glyph


def build_image(text: str, *, tracking: int = 0):
    if text == "":
        return Image.new("RGBA", (1, 20), (0, 0, 0, 0)).convert("P")

    glyphs = list(map(get_character, text))
    width = sum(glyph.width for glyph in glyphs) + tracking * (len(text) - 1)
    string = Image.new("RGBA", (width, 20), (0, 0, 0, 0))
    x = 0
    for glyph in glyphs:
        string.paste(glyph, (x, 1))
        x += glyph.width + tracking
    return string.convert("P")


TRICK_NAME_PATH = Path(__file__).parents[1] / "images/tricks"

def create_trick_images(trick_name: str):
    white = build_image(trick_name)

    whitepalette = white.getpalette("RGBA")
    redpalette = []
    for i in range(0, 12, 4):
        if whitepalette[i:i + 4] == [255, 255, 255, 255]:
            redpalette.extend([255, 0, 0, 255])
        else:
            redpalette.extend(whitepalette[i:i + 4])

    red = white.copy()
    red.putpalette(redpalette, "RGBA")

    filename = trick_name.lower().replace(" ", "_").replace("'", "")
    white.save(TRICK_NAME_PATH / f"{filename}.png")
    red.save(TRICK_NAME_PATH / f"{filename}-red.png")


parser = ArgumentParser()
parser.add_argument("string", type=str)
parser.add_argument("out", nargs="?", type=Path)
parser.add_argument("--trick")

args = parser.parse_args()
if args.trick:
    create_trick_images(args.string)
else:
    print(args.string, args.out)
    text_img = build_image(args.string)
    text_img.save(args.out or "text.png")
