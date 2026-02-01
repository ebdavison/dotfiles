#!/bin/env python3

import argparse
import qrcode
from qrcode.constants import *
from qrcode.image.styledpil import StyledPilImage
from qrcode.image.styles.moduledrawers.pil import CircleModuleDrawer


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument("initstr", type=str, help="string to encode")
    parser.add_argument("outfile", type=str, help="output filename")
    parser.add_argument("--bs", type=int, help="box size", default=10)
    parser.add_argument("-b", type=int, help="border", default=4)
    parser.add_argument("-v", type=int, help="version", default=2)
    parser.add_argument("-e", type=int, help="error correction", default=1)

    args = parser.parse_args()
    return args


correction_map = {
    0: ERROR_CORRECT_L,
    1: ERROR_CORRECT_M,
    2: ERROR_CORRECT_Q,
    3: ERROR_CORRECT_H,
}


def mk_qrcode(
    initstr, size, border, version, correction, color, back, outfile
):
    qr = qrcode.QRCode(
        version=version,
        error_correction=correction_map[correction],
        box_size=size,
        border=border,
    )
    qr.add_data(initstr)
    qr.make(fit=True)
    img_pil = qr.make_image(
        image_factory=StyledPilImage,
        factory=CircleModuleDrawer(),
        back_color=color,
        fill_color=back,
    )
    img_pil.save(outfile)


args = get_args()
initstr = args.initstr
outfile = args.outfile
box_size = args.bs
border_size = args.b
version = args.v
error_corr = args.e

mk_qrcode(
    initstr,
    box_size,
    border_size,
    version,
    error_corr,
    "white",
    "black",
    outfile,
)
