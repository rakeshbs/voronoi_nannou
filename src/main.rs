use bytemuck;
use nannou::{
    prelude::*,
    rand::random_range,
    wgpu::{RenderPipelineDescriptor, ShaderModuleDescriptor},
};

// nannou code logic skeleton
//
//

const NUM_SITES: usize = 1024;

#[repr(C)]
#[derive(Clone, Copy, bytemuck::Pod, bytemuck::Zeroable)]
struct Site {
    position: [f32; 2],
    _pad: [f32; 2],
}

struct Model {
    shader: wgpu::ShaderModule,
    pipeline: wgpu::RenderPipeline,
    site_buffer: wgpu::Buffer,
    bind_group: wgpu::BindGroup,
    base_sites: Vec<[f32; 2]>, // store static base positions
    amplitudes: Vec<f32>,
}

fn model(_app: &App) -> Model {
    let window_id = _app.new_window().size(800, 800).view(view).build().unwrap();
    let window = _app.window(window_id).unwrap();
    let device = window.device();
    let queue = window.queue();

    let mut base_sites = vec![];
    let mut sites = [Site {
        position: [0.0, 0.0],
        _pad: [0.0, 0.0],
    }; NUM_SITES];
    let mut amplitudes = vec![0.0; NUM_SITES];

    for site in &mut sites {
        let x = random();
        let y = random();
        site.position = [x, y];
        base_sites.push([x, y]);

        amplitudes.push(random_range(0.01, 0.05));
    }

    let voronoi_shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
        label: Some("Voronoi Shader"),
        source: wgpu::ShaderSource::Wgsl(include_str!("voronoi_shader.wgsl").into()),
    });

    let site_buffer = device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
        label: Some("Site Buffer"),
        contents: bytemuck::cast_slice(&sites),
        usage: wgpu::BufferUsages::STORAGE | wgpu::BufferUsages::COPY_DST,
    });

    let bind_group_layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
        label: Some("Bind Group Layout"),
        entries: &[wgpu::BindGroupLayoutEntry {
            binding: 0,
            visibility: wgpu::ShaderStages::FRAGMENT,
            ty: wgpu::BindingType::Buffer {
                ty: wgpu::BufferBindingType::Storage { read_only: true },
                has_dynamic_offset: false,
                min_binding_size: None,
            },
            count: None,
        }],
    });

    let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
        label: Some("Bind Group"),
        layout: &bind_group_layout,
        entries: &[wgpu::BindGroupEntry {
            binding: 0,
            resource: site_buffer.as_entire_binding(),
        }],
    });

    let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
        label: Some("Render Pipeline Layout"),
        bind_group_layouts: &[&bind_group_layout],
        push_constant_ranges: &[],
    });

    let pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
        label: Some("Render Pipeline"),
        layout: Some(&pipeline_layout),
        vertex: wgpu::VertexState {
            module: &voronoi_shader,
            entry_point: "vs_main",
            buffers: &[],
        },
        fragment: Some(wgpu::FragmentState {
            module: &voronoi_shader,
            entry_point: "fs_main",
            targets: &[Some(wgpu::ColorTargetState {
                format: wgpu::TextureFormat::Rgba16Float,
                blend: Some(wgpu::BlendState::REPLACE),
                write_mask: wgpu::ColorWrites::ALL,
            })],
        }),
        primitive: wgpu::PrimitiveState {
            topology: wgpu::PrimitiveTopology::TriangleList,
            strip_index_format: None,
            front_face: wgpu::FrontFace::Ccw,
            cull_mode: Some(wgpu::Face::Back),
            polygon_mode: wgpu::PolygonMode::Fill,
            conservative: false,
            unclipped_depth: false,
        },
        depth_stencil: None,
        multisample: wgpu::MultisampleState {
            count: 4,
            mask: !0,
            alpha_to_coverage_enabled: false,
        },
        multiview: None,
    });

    Model {
        shader: voronoi_shader,
        pipeline,
        site_buffer,
        bind_group,
        base_sites,
        amplitudes,
    }
}

fn update(app: &App, model: &mut Model, _update: Update) {
    let time = app.time;

    let mut animated_sites = [Site {
        position: [0.0, 0.0],
        _pad: [0.0, 0.0],
    }; NUM_SITES];

    for (i, base) in model.base_sites.iter().enumerate() {
        let angle = time + i as f32 * 0.03; // unique phase for each
        let radius = model.amplitudes[i] * time.sin() * 0.5 + 0.1;

        let x = base[0] + angle.sin() * radius;
        let y = base[1] + angle.cos() * radius;

        // Keep within [0,1]
        let x = x.clamp(0.0, 1.0);
        let y = y.clamp(0.0, 1.0);

        animated_sites[i] = Site {
            position: [x, y],
            _pad: [0.0, 0.0],
        };
    }
    // Write to GPU
    let binding = app.main_window();
    let queue = binding.queue();
    queue.write_buffer(&model.site_buffer, 0, bytemuck::cast_slice(&animated_sites));
}

fn view(_app: &App, _model: &Model, _frame: Frame) {
    let device = _frame.device_queue_pair().device();
    let queue = _frame.device_queue_pair().queue();

    let mut encoder = device.create_command_encoder(&wgpu::CommandEncoderDescriptor {
        label: Some("Render Encoder"),
    });

    let mut render_pass = encoder.begin_render_pass(&wgpu::RenderPassDescriptor {
        label: Some("Render Pass"),
        color_attachments: &[Some(wgpu::RenderPassColorAttachment {
            view: &_frame.texture_view(),
            resolve_target: None,
            ops: wgpu::Operations {
                load: wgpu::LoadOp::Clear(wgpu::Color::BLACK),
                store: true,
            },
        })],
        depth_stencil_attachment: None,
    });

    render_pass.set_pipeline(&_model.pipeline);
    render_pass.set_bind_group(0, &_model.bind_group, &[]);
    render_pass.draw(0..3, 0..1);
    drop(render_pass);
    queue.submit(Some(encoder.finish()));
}

fn main() {
    nannou::app(model).update(update).view(view).run();
}
