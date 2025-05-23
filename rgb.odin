package color

import "core:c/libc"
import "core:fmt"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:math"
import "core:time"
import "core:math/linalg"
import "vendor:glfw"
import vk "vendor:vulkan"
import "vendor:stb/image"

// 3 component Color in the srgb space with gamma correction applied
SRGBColor :: distinct [3]f64
// 4 component Color in the srgb space with gamma correction applied
SRGBAColor :: distinct [4]f64

// 3 component Color in the srgb space with gamma correction applied each component as a u8
SRGBU8Color :: distinct [3]u8
// 4 component Color in the srgb space with gamma correction applied each component as a u8
SRGBAU8Color :: distinct [4]u8

// 3 component Color in the linear srgb space this means no gamma correction has been applied
LinearRGBColor :: distinct [3]f64
// 4 component Color in the linear srgb space this means no gamma correction has been applied
LinearRGBAColor :: distinct [4]f64

// 3 component Color in the linear srgb space this means no gamma correction has been applied each component as a u8
LinearRGBU8Color :: distinct [3]u8
// 4 component Color in the linear srgb space this means no gamma correction has been applied each component as a u8
LinearRGBAU8Color :: distinct [4]u8


srgbu8_from_hex :: proc(hex : u32) -> SRGBU8Color
{
    return SRGBU8Color{
        u8((hex >> 16) & 0xFF),
        u8((hex >> 8) & 0xFF),
        u8((hex >> 0) & 0xFF)
    }
}

srgbau8_from_hex :: proc(hex : u32) -> SRGBAU8Color
{
    return SRGBAU8Color{
        u8((hex >> 24) & 0xFF),
        u8((hex >> 16) & 0xFF),
        u8((hex >> 8) & 0xFF),
        u8((hex >> 0) & 0xFF)
    }
}

xyz_to_linear_rgb :: proc(xyz : XYZColor) -> LinearRGBColor
{
    xyz_to_rgb_matrix := matrix[3, 3]f64{
        3.2406255, -1.537208, -0.4986286,
        -0.9689307, 1.8757561, 0.0415175,
        0.0557101, -0.2040211, 1.0569959
    }
    return xyz_to_rgb_matrix * xyz
}

linear_rgb_to_xyz :: proc(linear_rgb : LinearRGBColor) -> XYZColor
{
    xyz_to_rgb_matrix := matrix[3, 3]f64{
        3.2406255, -1.537208, -0.4986286,
        -0.9689307, 1.8757561, 0.0415175,
        0.0557101, -0.2040211, 1.0569959
    }
    return linalg.inverse(xyz_to_rgb_matrix) * linear_rgb
}

gamma_correction :: proc(c : f64) -> f64
{
    if (c <= 0.0031308)
    {
        return 12.92 * c;
    }
    else
    {
        return 1.055 * math.pow(c, 1.0 / 2.4) - 0.055;
    }
}

inverse_gamma_correction :: proc(v : f64) -> f64
{
    if v <= 0.04045
    {
        return v / 12.92
    }
    else
    {
        return math.pow((v + 0.055) / 1.055, 2.4);
    }
}

srgb_to_linear_rgb :: proc(srgb : SRGBColor) -> LinearRGBColor
{
    return LinearRGBColor{
        inverse_gamma_correction(srgb.x),
        inverse_gamma_correction(srgb.y),
        inverse_gamma_correction(srgb.z)
    }
}

linear_rgb_to_srgb :: proc(rgb_linear : LinearRGBColor) -> SRGBColor
{
    return SRGBColor{
        math.clamp(gamma_correction(rgb_linear.x), 0, 1),
        math.clamp(gamma_correction(rgb_linear.y), 0, 1),
        math.clamp(gamma_correction(rgb_linear.z), 0, 1)
    }
}

srgba_to_linear_rgba :: proc(srgb : SRGBAColor) -> LinearRGBAColor
{
    return LinearRGBAColor{
        inverse_gamma_correction(srgb.x),
        inverse_gamma_correction(srgb.y),
        inverse_gamma_correction(srgb.z),
        inverse_gamma_correction(srgb.w),
    }
}

linear_rgba_to_srgba :: proc(rgb_linear : LinearRGBAColor) -> SRGBAColor
{
    return SRGBAColor{
        math.clamp(gamma_correction(rgb_linear.x), 0, 1),
        math.clamp(gamma_correction(rgb_linear.y), 0, 1),
        math.clamp(gamma_correction(rgb_linear.z), 0, 1),
        math.clamp(gamma_correction(rgb_linear.w), 0, 1)
    }
}

xyz_to_srgb :: proc(xyz : XYZColor) -> SRGBColor
{
    rgb_linear := xyz_to_linear_rgb(xyz)
    return linear_rgb_to_srgb(rgb_linear)
}

srgb_to_xyz :: proc(srgb : SRGBColor) -> XYZColor
{
    rgb_linear := srgb_to_linear_rgb(srgb)
    return linear_rgb_to_xyz(rgb_linear)
}

srgb_to_srgbu8 :: proc(srgb : SRGBColor) -> SRGBU8Color
{
    return SRGBU8Color{
        u16(srgb.x * 256) >= 256 ? 255 : u8(srgb.x * 256),
        u16(srgb.y * 256) >= 256 ? 255 : u8(srgb.y * 256),
        u16(srgb.z * 256) >= 256 ? 255 : u8(srgb.z * 256),
    }
}

srgba_to_srgbau8 :: proc(srgb : SRGBAColor) -> SRGBAU8Color
{
    return SRGBAU8Color{
        u16(srgb.x * 256) >= 256 ? 255 : u8(srgb.x * 256),
        u16(srgb.y * 256) >= 256 ? 255 : u8(srgb.y * 256),
        u16(srgb.z * 256) >= 256 ? 255 : u8(srgb.z * 256),
        u16(srgb.w * 256) >= 256 ? 255 : u8(srgb.w * 256),
    }
}

srgbu8_to_srgb :: proc(srgb_u8 : SRGBU8Color) -> SRGBColor
{
    return SRGBColor{
        f64(srgb_u8.x) / 255,
        f64(srgb_u8.y) / 255,
        f64(srgb_u8.z) / 255
    }
}

srgbau8_to_srgba :: proc(srgba_u8 : SRGBAU8Color) -> SRGBAColor
{
    return SRGBAColor{
        f64(srgba_u8.x) / 255,
        f64(srgba_u8.y) / 255,
        f64(srgba_u8.z) / 255,
        f64(srgba_u8.w) / 255,
    }
}

linear_rgbu8_to_linear_rgba :: proc(linear_rgb_u8 : LinearRGBU8Color) -> LinearRGBColor
{
    return LinearRGBColor{
        f64(linear_rgb_u8.x) / 255,
        f64(linear_rgb_u8.y) / 255,
        f64(linear_rgb_u8.z) / 255
    }
}

linear_rgbau8_to_linear_rgba :: proc(linear_rgba_u8 : LinearRGBAU8Color) -> LinearRGBAColor
{
    return LinearRGBAColor{
        f64(linear_rgba_u8.x) / 255,
        f64(linear_rgba_u8.y) / 255,
        f64(linear_rgba_u8.z) / 255,
        f64(linear_rgba_u8.w) / 255
    }
}

// alpha transparency over operator
alpha_transparency_over :: proc(above : LinearRGBAColor, below : LinearRGBAColor) -> LinearRGBAColor
{
    alpha_out := above.a + below.a * (1 - above.a)
    color_out := (above.rgb * above.a + below.rgb * below.a * (1 - above.a)) / alpha_out
    return LinearRGBAColor{color_out.r, color_out.g, color_out.b, alpha_out}
}
