struct VertexOutput {
    @builtin(position) position: vec4<f32>,
    @location(0) uv: vec2<f32>,
};

@vertex
fn vs_main(@builtin(vertex_index) vertex_index: u32) -> VertexOutput {
    // Fullscreen triangle (no vertex buffer needed)
    var pos = array<vec2<f32>, 3>(
        vec2<f32>(-1.0, -3.0),
        vec2<f32>(3.0, 1.0),
        vec2<f32>(-1.0, 1.0)
    );
    var uv = array<vec2<f32>, 3>(
        vec2<f32>(0.0, 0.0),
        vec2<f32>(2.0, 1.0),
        vec2<f32>(0.0, 1.0)
    );

    var out: VertexOutput;
    out.position = vec4<f32>(pos[vertex_index], 0.0, 1.0);
    out.uv = uv[vertex_index];
    return out;
}

struct Site {
    pos: vec2<f32>,
    _pad: vec2<f32>, // Add padding to make the size 16 bytes
};

@group(0) @binding(0)
var<uniform> sites: array<Site, 64>;

@fragment
fn fs_main(@location(0) fragCoord: vec2<f32>) -> @location(0) vec4<f32> {
    var uv = fragCoord;

    var minDist = 10000.0;
    var nearestIndex = 0u;

    for (var i = 0u; i < 64u; i = i + 1u) {
        let dist = distance(uv, sites[i].pos);
        if dist < minDist {
            minDist = dist;
            nearestIndex = i;
        }
    }

    // Fake color based on index
    let color = vec3<f32>(
        f32(nearestIndex % 3u) * 0.3,
        f32((nearestIndex + 1u) % 5u) * 0.2,
        f32((nearestIndex + 2u) % 7u) * 0.1
    );
    return vec4<f32>(color, 1.0);
}
