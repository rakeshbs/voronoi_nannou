struct Site {
    pos: vec2<f32>,
    _pad: vec2<f32>,
};

@group(0) @binding(0)
var<storage, read> sites: array<Site, 1024>;

fn get_palette_color(index: u32) -> vec3<f32> {
    let hashed = (index * 1664525u + 1013904223u) % 8u;

    var color: vec3<f32>;
    switch (hashed) {
        case 0u:  { color = vec3<f32>(0.07, 0.16, 0.24); } // Deep Blue
        case 1u:  { color = vec3<f32>(0.0, 0.39, 0.40); }  // Teal
        case 2u:  { color = vec3<f32>(0.96, 0.64, 0.38); } // Gold
        case 3u:  { color = vec3<f32>(0.74, 0.29, 0.32); } // Muted Red
        case 4u:  { color = vec3<f32>(0.24, 0.09, 0.26); } // Dark Violet
        case 5u:  { color = vec3<f32>(0.36, 0.37, 0.59); } // Slate
        case 6u:  { color = vec3<f32>(0.10, 0.51, 0.77); } // Cyan Blue
        case 7u:  { color = vec3<f32>(0.90, 0.44, 0.32); } // Clay Orange
        default:  { color = vec3<f32>(0.05, 0.05, 0.05); } // fallback
    }
    return color;
}

fn procedural_color(i: u32) -> vec3<f32> {
    let f = f32(i);

    let r = 0.1 + 0.2 * sin(f * 0.3 + 0.0);
    let g = 0.05 + 0.15 * sin(f * 0.3 + 2.0);
    let b = 0.1 + 0.2 * sin(f * 0.3 + 4.0);

    return vec3<f32>(r, g, b);
}

struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    var positions = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -3.0),
        vec2<f32>(3.0, 1.0),
        vec2<f32>(-1.0, 1.0),
    );
    var uvs = array<vec2<f32>, 3>(
        vec2<f32>(0.0, 0.0),
        vec2<f32>(2.0, 1.0),
        vec2<f32>(0.0, 1.0),
    );

    var out: VertexOutput;
    out.position = vec4<f32>(positions[vertex_index], 0.0, 1.0);
    out.uv = uvs[vertex_index];
    return out;
}


@fragment
fn fs_main(@location(0) uv: vec2<f32>) -> @location(0) vec4<f32> {
    var minDist = 10000.0;
    var nearestIndex = 0u;

    for (var i = 0u; i < 1024u; i = i + 1u) {
        let d = distance(uv, sites[i].pos);
        if d < minDist {
            minDist = d;
            nearestIndex = i;
        }
    }

    let baseColor = procedural_color(nearestIndex);
    return vec4<f32>(baseColor, 1.0);
}
