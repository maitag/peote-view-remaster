package peote.view;

class Shader 
{
	// -------------------------- VERTEX SHADER TEMPLATE --------------------------------	
	@:allow(peote.view) static var vertexShader(default, null):String =		
	"
	::if isES3::#version 300 es::end::
	
	// Uniforms -------------------------
	::if isUBO::
	//layout(std140) uniform uboView
	uniform uboView
	{
		vec2 uResolution;
		vec2 uViewOffset;
		float uViewZoom;
	};
	//layout(std140) uniform uboDisplay
	uniform uboDisplay
	{
		vec2 uOffset;
		float uZoom;
	};
	::else::
	uniform vec2 uResolution;
	uniform vec2 uOffset;
	uniform float uZoom;
	::end::
	
	::UNIFORM_TIME::
	
	// Attributes -------------------------
	::IN:: vec2 aPosition;
	
	::ATTRIB_POS::
	::ATTRIB_SIZE::
	::ATTRIB_TIME::
	::ATTRIB_COLOR::
	::ATTRIB_ROTZ::
	::ATTRIB_PIVOT::
	::ATTRIB_UNIT::
	::ATTRIB_SLOT::
	::ATTRIB_TILE::
		
	//aElement
	
	// custom Attributes --
	//aCustom0
	
	// Varyings ---------------------------
	::OUT_COLOR::
	::if hasTEXTURES::
		::OUT_TEXCOORD::
		::OUT_UNIT::
		::OUT_SLOT::
		::OUT_TILE::
	::end::

	// PICKING  ::if isES3:: flat out int instanceID; ::end::
	
	void main(void) {
		::CALC_TIME::		
		::CALC_SIZE::
		::CALC_PIVOT::		
		::CALC_ROTZ::
		::CALC_POS::
		::CALC_COLOR::
		::if hasTEXTURES::
			::CALC_TEXCOORD::
			::CALC_UNIT::
			::CALC_SLOT::
			::CALC_TILE::
		::end::
		
		// PICKING instanceID = gl_InstanceID;
		
		float zoom = uZoom ::if isUBO:: * uViewZoom ::end::;
		float width = uResolution.x;
		float height = uResolution.y;
		::if isUBO::
		float deltaX = (uOffset.x  + uViewOffset.x) / uZoom;
		float deltaY = (uOffset.y  + uViewOffset.y) / uZoom;
		::else::
		float deltaX = uOffset.x;
		float deltaY = uOffset.y;
		::end::
		
		//float right = width-deltaX*zoom;
		//float left = -deltaX*zoom;
		//float bottom = height-deltaY*zoom;
		//float top = -deltaY * zoom;
			
		gl_Position = mat4 (
			//vec4(2.0 / (right - left)*zoom, 0.0, 0.0, 0.0),
			//vec4(0.0, 2.0 / (top - bottom)*zoom, 0.0, 0.0),
			//vec4(0.0, 0.0, -1.0, 0.0),
			//vec4(-(right + left) / (right - left), -(top + bottom) / (top - bottom), 0.0, 1.0)
			
			vec4(2.0 / width*zoom, 0.0, 0.0, 0.0),
			vec4(0.0, -2.0 / height*zoom, 0.0, 0.0),
			vec4(0.0, 0.0, -1.0, 0.0),
			vec4(2.0*deltaX*zoom/width-1.0, 1.0-2.0*deltaY*zoom/height, 0.0, 1.0)
		)
		* vec4 (pos ,
			::ZINDEX::
			, 1.0
			);
	}
	";
	
	
	
	// ------------------------ FRAGMENT SHADER TEMPLATE --------------------------------	
	@:allow(peote.view) static var fragmentShader(default, null):String =	
	"
	::if isES3::#version 300 es::end::
	
    precision highp float;
    //precision mediump float;
	
	::FRAGMENT_PROGRAM_UNIFORMS::
	
	::IN_COLOR::
	::if hasTEXTURES::
		::IN_TEXCOORD::
		::IN_UNIT::
		::IN_SLOT::
		::IN_TILE::
	::end::
	
	::if isES3::
	//flat in int instanceID;
	out vec4 Color;
	// PICKING out int color;
	::end::

	
	void main(void)
	{	
		vec4 texel = ::FRAGMENT_CALC_COLOR::;
		
		::if hasTEXTURES::
		
		::foreach TEXTURES::
			// LAYER ::LAYER::
			::foreach ELEMENT_LAYERS::
			::if_ELEMENT_LAYER::
				vec4 texel::LAYER::;
				::foreach UNITS::
				::if !FIRST ::else ::end::::if !LAST ::if (::UNIT:: < ::UNIT_VALUE::)::end::
				{ texel::LAYER:: = texture::if !isES3::2D::end::(::TEXTURE::, ::TEXCOORD::); }
				::end::
			::end_ELEMENT_LAYER::
			::end::
		::end::
		
		// calc final texel
		//texel = texel * texture::if !isES3::2D::end::(uTexture0, vTexCoord);
		texel = texel0; // TODO

		if (texel.a == 0.0) discard;
		
		::end::
		
		::if !isES3::gl_Frag::end::Color = texel;
		
		// TODO: check this fix for problem on old FF if alpha goes zero
		::if !isES3::gl_Frag::end::Color.w = clamp(::if !isES3::gl_Frag::end::Color.w, 0.003, 1.0);
		
		// PICKING ::if isES3::color::else::gl_FragColor::end:: =  instanceID*50;
	}
	";

	
	
	
	
}