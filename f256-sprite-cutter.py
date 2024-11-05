from PIL import Image
import sys
from math import sqrt

def uniquepalette(image):
    hist = set()
    for j in range(image.size[1]):
        for i in range(image.size[0]):
            hist.add(image.getpixel((i,j)))
    return hist

def palette_gen(pal_set):
    new = set()
    # this does nothing but was thinking we could squash extra colors here if we wanted
    for rgb in pal_set:
        new.add(rgb)
    return new

def pal_to_clut(pal):
    clut = []
    for rgb in pal:
        if rgb[0] == -1:
             clut.append(0)
             clut.append(0)
             clut.append(0)
             clut.append(0)
        else:
            clut.append(rgb[2])
            clut.append(rgb[1])
            clut.append(rgb[0])
            clut.append(0xFF)
    return clut

def cut_sprite(x, y, size, name):
    print(f'Cutting sprite -> x: {x} \ty: {y} \tsize: {size} \tname: {name}')
    pixel_bytes = []
    for j in range(y,y+size):
        for i in range(x,x+size):
            p1 = rgb_img.getpixel((i,j))
            if p1[3] == 0:
                pixel_bytes.append(int(0).to_bytes(1, 'big'))
                continue
            nearest_idx1 = image_pal.index(min(image_pal, key=lambda x: distance3d(x[0], x[1], x[2], p1[0], p1[1], p1[2])))
            pixel_bytes.append(nearest_idx1.to_bytes(1, 'big'))
    return pixel_bytes

def code_hex_bytes(data, perline=8, byteshack=True):
    result = ''
    for i in range(0, len(data), perline):
        # Extract 8 bytes from the binary data
        chunk = data[i:i+perline]
        if byteshack:
            hex_bytes = [f'{b[0]:02X}' for b in chunk]
        else:
            hex_bytes = [f'{b:02X}' for b in chunk]
        hex_bytes_str = ','.join(hex_bytes)
        result += f'    hex {hex_bytes_str}\n'
    return result


def distance3d(x1, y1, z1, x2, y2, z2):
    return sqrt((x2 - x1)**2 + (y2 - y1)**2 + (z2 - z1)**2)

if __name__ == "__main__":
    if len(sys.argv) < 4:
        print("Usage: python png-to-i256.py sprites.png sprite_list.txt sprites.s")
        print("\n\ntextfile is lines of x,y offset, size and optionally name, e.g.:")
        print("50,100,32,ship\n82,100,8, bullet\netc...\n\n")
    else:
        rgb_img = Image.open(sys.argv[1]).convert("RGBA")    # create the pixel map

        #todo: sorted probably isn't right for this tuple format
        orig_pal = sorted(uniquepalette(rgb_img))   # source palette from gif/png
        print(f'Colors in image = {len(orig_pal)}')
        new_pal = palette_gen(orig_pal)             # our 4-bit colorspace versions
        image_pal = list(new_pal)                   # as a list to index palette colors
        print(f'Colors in new pal = {len(new_pal)}')
        if len(new_pal) < 256:
            print('auto-moving palette out of color 0')
            image_pal.insert(0,(-1,-1,-1))

        sprites = []
        with open(sys.argv[2], 'r') as file:
            linenum = 0
            for line in file:
                linenum += 1
                s = line.strip().split(',')
                # set name if needed
                if len(s) == 3:
                    s[3] = f'spr_{s[0]}_{s[1]}_{s[2]}'
                
                if len(s) > 2:
                    sprdata = cut_sprite(int(s[0]), int(s[1]), int(s[2]), s[3])
                else:
                    print(f'skipping line: {linenum}')
                
                sprites.append(f'{s[3]}_size = {s[2]}\n{s[3]}\n{code_hex_bytes(sprdata,int(s[2]))}\n\n')
        # print("\n".join(sprites))

        clut = pal_to_clut(image_pal)
        # print(f'clut_x\n{code_hex_bytes(clut,4, False)}')

        out = "\n".join(sprites)
        out += f'clut_x_len = #${int(len(clut)/4):02X} ; {int(len(clut)/4)}\n'
        out += f'clut_x\n{code_hex_bytes(clut,4, False)}'
        with open(sys.argv[3], "w") as file:
            file.write(f'** GENERATED WITH F256-SPRITE-CUTTER\n{out}\n')
