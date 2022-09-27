shader_type canvas_item;

uniform sampler2D icon;
uniform bool use_icon = false;
uniform vec4 color_body : hint_color = vec4(1,1,1,1);
uniform vec4 color_trim : hint_color = vec4(0,0,0,1);
uniform float trim_width = 1.0;
uniform float angle_start = 0.0;
uniform float angle_end = 0.7853982;
uniform float angle_offset = 0.0;
uniform float base_size = 40.0;
uniform float radius_inner = 25.0;
uniform float radius_outer = 40.0;

vec4 IconColor(vec2 uv){
	if (!use_icon){return vec4(0,0,0,0);}
	float center_angle = radians(angle_start + ((angle_end - angle_start) * 0.5)) + 3.14159;
	center_angle = mod(center_angle + radians(angle_offset), radians(360.0));
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

float det(vec2 a, vec2 b){
	return (a.x*b.y) - (a.y*b.x);
}

float GetAngleBetween(vec2 a, vec2 b){
	float pi = 3.14159;
	return atan(det(a,b), dot(a,b)) + pi;
}

bool IsAngleWithinArc(float angle){
	float as = radians(mod(angle_start + angle_offset, 360.0));
	float ae = radians(mod(angle_end + angle_offset, 360.0));
	if (ae > as){
		return angle >= as && angle <= ae;
	}
	return (angle >= 0.0 && angle <= ae) || (angle >= as && angle <= radians(360.0));
}

void fragment(){
	vec2 origin = vec2(0.5, 0.5);
	vec4 color = vec4(0,0,0,0);
	float angle = GetAngleBetween(vec2(1,0), normalize(UV - origin));
	float _irad = (radius_inner / base_size) * 0.5;
	float _orad = (radius_outer / base_size) * 0.5;
	//float _tw = (trim_width / base_size) * 0.5;
	float _tw = ((_orad - _irad) * 0.5) * trim_width;
	float dist = distance(UV, origin);
	if (IsAngleWithinArc(angle)){
		if (dist <= _orad && dist >= _irad){
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
	COLOR = color;
}