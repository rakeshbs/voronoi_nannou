struct Site {
    pos: vec2<f32>,
    _pad: vec2<f32>,
};

@group(0) @binding(0)
var<storage, read> sites: array<Site, 1024>;

fn get_palette_color(index: u32) -> vec3<f32> {
    let hashed = (index * 1664525u + 1013904223u) % 16u;

    var color: vec3<f32>;
    switch (hashed) {
        case 0u:  { color = vec3<f32>(0.85, 0.1, 0.2); }
        case 1u:  { color = vec3<f32>(0.1, 0.85, 0.2); }
        case 2u:  { color = vec3<f32>(0.1, 0.3, 0.9); }
        case 3u:  { color = vec3<f32>(0.8, 0.7, 0.2); }
        case 4u:  { color = vec3<f32>(0.75, 0.2, 0.85); }
        case 5u:  { color = vec3<f32>(0.1, 0.9, 0.7); }
        case 6u:  { color = vec3<f32>(0.9, 0.4, 0.1); }
        case 7u:  { color = vec3<f32>(0.3, 0.9, 0.1); }
        case 8u:  { color = vec3<f32>(0.6, 0.2, 0.9); }
        case 9u:  { color = vec3<f32>(0.9, 0.2, 0.6); }
        case 10u: { color = vec3<f32>(0.2, 0.9, 0.4); }
        case 11u: { color = vec3<f32>(0.5, 0.5, 0.9); }
        case 12u: { color = vec3<f32>(0.9, 0.6, 0.3); }
        case 13u: { color = vec3<f32>(0.2, 0.2, 0.8); }
        case 14u: { color = vec3<f32>(0.2, 0.8, 0.2); }
        case 15u: { color = vec3<f32>(0.8, 0.2, 0.2); }
        default:  { color = vec3<f32>(0.0, 0.0, 0.0); }
    }
    return color;
}

fn procedural_color(i: u32) -> vec3<f32> {
    let f = f32(i);
    return vec3<f32>(
        0.4 + 0.5 * sin(f * 0.3 + 0.0),
        0.4 + 0.5 * sin(f * 0.3 + 2.0),
        0.4 + 0.5 * sin(f * 0.3 + 4.0)
    );
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

    for (var i = 0u; i < 64u; i = i + 1u) {
        let dist = distance(uv, sites[i].pos);
        if dist < minDist {
            minDist = dist;
            nearestIndex = i;
        }
    }

    var color: vec3<f32> = procedural_color(nearestIndex);
    return vec4<f32>(color, 1.0);
}
