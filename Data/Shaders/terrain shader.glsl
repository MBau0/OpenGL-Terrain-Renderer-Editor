#Vertex

#version 450 core

const int vertex_indices[6] = {2, 0, 1, 2, 3, 1};

layout (location = 0) in vec2 vertex;
layout (location = 1) in vec2 uv;

uniform int width;
uniform int length;
uniform float space;
uniform vec4 quad;

uniform vec3 test_light_position;

uniform mat4 projection;
uniform mat4 view;
uniform mat4 model;

layout (binding = 0) uniform samplerBuffer heights;
layout (binding = 1) uniform samplerBuffer normals;

out VS {
	float height;
	vec2 uv;
	vec3 normal;

	vec3 position;
	vec2 position_alpha;
} dest;

float get_height(const int vertex) {
	const int index = gl_InstanceID + (gl_InstanceID / width);

	switch(vertex_indices[vertex]) {
		case 0 :	return texelFetch(heights, index).r;break;
		case 1 :	return texelFetch(heights, index + 1).r;	break;
		case 2 :	return texelFetch(heights, index + (width + 1)).r;	break;
		case 3 :	return texelFetch(heights, index + 1 + (width + 1)).r;	break;
	}
}

vec3 get_normal(const int vertex) {
	const int index = gl_InstanceID + (gl_InstanceID / width);

	switch(vertex_indices[vertex]) {
		case 0 :	return texelFetch(normals, index).xyz;	break;
		case 1 :	return texelFetch(normals, index + 1).xyz;	break;
		case 2 :	return texelFetch(normals, index + (width + 1)).xyz;	break;
		case 3 :	return texelFetch(normals, index + 1 + (width + 1)).xyz;	break;
	}
}

void main() {
	const float height = get_height(gl_VertexID);
	const vec3 normal = get_normal(gl_VertexID);
	const vec2 position = vec2(gl_InstanceID % width, gl_InstanceID / width);
	const float x = (vertex.x + position.x) * space + quad.x;
	const float z = (vertex.y + position.y) * space + quad.y;

	gl_Position = projection * view * model * vec4(x, height, z, 1.0);

	dest.height = height;
	dest.uv = uv;
	dest.normal = normal;

	dest.position = vec3(x, height, z);
	dest.position_alpha = vec2(x / width, z / length);
}

#End

#Fragment

#version 450 core

layout (location = 0) out vec3 f_color;

uniform vec3 test_light_position;

in VS {
	float height;
	vec2 uv;
	vec3 normal;

	vec3 position;
	vec2 position_alpha;
} source;

layout (binding = 2) uniform sampler2D blend_map;

layout (binding = 3) uniform sampler2D tile_texture1;
layout (binding = 4) uniform sampler2D tile_texture2;
layout (binding = 5) uniform sampler2D tile_texture3;
layout (binding = 6) uniform sampler2D tile_texture4;

void main() {
	//vec3 color = texture(tile_texture, source.uv).xyz;
	//vec3 color = vec3(source.height / 50, .6, .2);
	vec3 color;

	//if(abs(normalize(source.normal).y) < .5) {
	//	color = texture(tile_texture4, source.uv).rgb;
	//}
	//else {
	//	color = texture(tile_texture1, source.uv).rgb;
	//}

	vec2 blend_map_position = vec2(source.position_alpha.x, source.position_alpha.y);
	vec4 blend_map_texture = texture(blend_map, blend_map_position);
	float back_texture_amount = 1 - (blend_map_texture.r + blend_map_texture.g + blend_map_texture.b + blend_map_texture.a);
	color = vec3(.8, .8, .8) * back_texture_amount;

	vec3 t_color1 = texture(tile_texture1, source.uv).rgb * texture(blend_map, blend_map_position).r;
	vec3 t_color2 = texture(tile_texture2, source.uv).rgb * texture(blend_map, blend_map_position).g;
	vec3 t_color3 = texture(tile_texture3, source.uv).rgb * texture(blend_map, blend_map_position).b;
	vec3 t_color4 = texture(tile_texture4, source.uv).rgb * texture(blend_map, blend_map_position).a;

	color = color + t_color1 + t_color2 + t_color3 + t_color4;

	vec3 light_color = vec3(.6, .6, .6);

	vec3 normal = normalize(source.normal);
	vec3 light_position = vec3(0, 50, 0);
	vec3 light_direction = normalize(light_position - source.position);

	float diff = clamp(dot(normal, light_direction), 0, 1);
	vec3 diffuse = diff * light_color;
	vec3 ambient = vec3(.5, .5, .5);

	f_color = (ambient + diffuse) * color;

}

#End