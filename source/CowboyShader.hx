package;

import openfl.filters.BitmapFilterShader;
import openfl.utils.ByteArray;

class CowboyShader extends BitmapFilterShader
{
	@:glVertexHeader("uniform vec4 vertexMultiplier;")
	@:glVertexBody("gl_Position *= vertexMultiplier;")
	@:glFragmentHeader("uniform vec4 fragmentMultiplier;")
	@:glFragmentBody("gl_FragColor *= fragmentMultiplier;")
	public function new(code:ByteArray = null)
	{
		super(code);
	}
}
