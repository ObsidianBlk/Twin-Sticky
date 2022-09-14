shader_type canvas_item;

uniform sampler2D icon;
uniform vec4 color_body : hint_color = vec4(1,1,1,1);
uniform vec4 color_trim : hint_color = vec4(0,0,0,1);
uniform float trim_width = 1.0;
uniform float angle_start = 0.0;
uniform float angle_end = 0.7853982;
uniform float base_size = 40.0;
uniform float radius_inner = 25.0;
uniform float radius_outer = 40.0;

vec4 test(){return vec4(0,0,0,1);}

vec4 IconColor(vec2 uv){
	float center_angle = angle_start + ((angle_end - angle_start) * 0.5);
	vec2 direction = vec2(cos(center_angle), sin(center_angle));
	float arc_width = radius_outer - radius_inner;
	float center_radius = radius_inner + (arc_width * 0.5);
	center_radius = (center_radius / base_size) * 0.5;
	vec2 center_point = vec2(0.5, 0.5) + (direction * center_radius); 
	ivec2 icon_size = textureSize(icon, 0);
	float iw = (float(icon_size.x) / base_size) * 0.5;
	float ih = (float(icon_size.y) / base_size) * 0.5;
	
	vec4 color = vec4(0,0,0,0);
	if (uv.x >= center_point.x - (iw * 0.5) && uv.x <= center_point.x + (iw * 0.5)){
		if (uv.y >= center_point.y - (ih * 0.5) && uv.y <= center_point.y + (ih * 0.5)){
			vec2 pos = (uv - center_point);
			
			vec2 icon_uv = vec2(
				(pos.x / iw) + 0.5,
				(pos.y / ih) + 0.5
			);
			color = texture(icon, icon_uv);
		}
	}
	
	
	return color;
}

void fragment(){
	vec2 origin = vec2(0.5, 0.5);
	vec4 color = vec4(0,0,0,0);
	float angle = acos(dot(vec2(1,0), normalize(UV - origin)));
	float _irad = (radius_inner / base_size) * 0.5;
	float _orad = (radius_outer / base_size) * 0.5;
	float _tw = (trim_width / base_size) * 0.5;
	float dist = distance(UV, origin);
	if (angle >= angle_start && angle <= angle_end){
		if (dist <= _orad){
			if (dist >= _irad){
				if ((dist <= _orad && dist >= _orad - _tw) || (dist >= _irad && dist <= _irad + _tw)){
					color = color_trim;
				} else { 
					vec4 icolor = IconColor(UV);
					if (icolor.a <= 0.0){
						color = color_body;
					} else {
						color = vec4(mix(color_body.rgb, icolor.rgb, icolor.a), 1);
					}
				}
			}
		}
	}
	COLOR = color;
}