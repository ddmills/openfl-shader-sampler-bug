package;

import openfl.Vector;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.Matrix3D;

typedef GlyphData =
{
	var x:Float;
	var y:Float;
	var width:Float;
	var height:Float;
}

var vertexSource = "
attribute vec2 in_pos;
attribute vec2 in_uv;
varying vec2 uv;

uniform mat4 projection;

void main(void) {
	gl_Position = projection * vec4(in_pos.x, in_pos.y, 0, 1);
	uv = in_uv;
}";

var fragmentSource = #if !desktop "precision mediump float;" + #end

"varying vec2 uv;
uniform sampler2D tex_1;
uniform sampler2D tex_2;

void main(void)
{
	gl_FragColor = texture2D(tex_1, uv);
	gl_FragColor.b = 1.0;
}";

class GlyphBatch
{
	private var bm1:BitmapData;
	private var bm2:BitmapData;
	private var program:Program3D;

	private var projectionTransform:Matrix3D;
	private var bitmapRenderTransform:Matrix3D;

	private var vBuffer:VertexBuffer3D;
	private var iBuffer:IndexBuffer3D;

	private var bm1Texture:RectangleTexture;
	private var bm2Texture:RectangleTexture;

	private var maxGlyphCount:Int;
	private var glyphCount:Int;
	private var vertices:Vector<Float>;
	private var indices:Vector<Int>;
	private var vertexSize32:Int;

	public function new(bm1:BitmapData, bm2:BitmapData)
	{
		this.bm1 = bm1;
		this.bm2 = bm2;
		this.glyphCount = 0;
		this.maxGlyphCount = 10000;
	}

	public function add(g:GlyphData)
	{
		if (glyphCount >= maxGlyphCount)
		{
			trace("Max glyph batch count limit reached");
			return;
		}

		var i = glyphCount * vertexSize32 * 4; // four verts per glyph

		vertices[i++] = (g.x); // x
		vertices[i++] = (g.y); // y
		vertices[i++] = (0); // u
		vertices[i++] = (0); // v

		vertices[i++] = (g.x + g.width); // x
		vertices[i++] = (g.y); // y
		vertices[i++] = (1); // u
		vertices[i++] = (0); // v

		vertices[i++] = (g.x + g.width); // x
		vertices[i++] = (g.y + g.height); // y
		vertices[i++] = (1); // u
		vertices[i++] = (1); // v

		vertices[i++] = (g.x); // x
		vertices[i++] = (g.y + g.height); // y
		vertices[i++] = (0); // u
		vertices[i++] = (1); // v

		glyphCount++;
	}

	public function createProgram(ctx:Context3D)
	{
		var vCount = 4 * maxGlyphCount;
		var iCount = 6 * maxGlyphCount;

		vertexSize32 = 4;

		vertices = new Vector(vCount * vertexSize32, true);
		indices = new Vector(iCount, true);

		for (i in 0...maxGlyphCount)
		{
			var k = i << 2;
			var start = i * 6;
			indices[start] = k;
			indices[start + 1] = k + 1;
			indices[start + 2] = k + 2;
			indices[start + 3] = k;
			indices[start + 4] = k + 2;
			indices[start + 5] = k + 3;
		}

		program = ctx.createProgram(GLSL);
		program.uploadSources(vertexSource, fragmentSource);

		bm1Texture = ctx.createRectangleTexture(bm1.width, bm1.height, BGRA, false);
		bm1Texture.uploadFromBitmapData(bm1);

		bm2Texture = ctx.createRectangleTexture(bm2.width, bm2.height, BGRA, false);
		bm2Texture.uploadFromBitmapData(bm2);

		var targetSizeW = 600;
		var targetSizeH = 600;

		projectionTransform = new Matrix3D();
		projectionTransform.copyRawDataFrom(openfl.Vector.ofArray([
			2.0 / targetSizeW,                0.0,         0.0, 0.0,
			              0.0, -2.0 / targetSizeH,         0.0, 0.0,
			              0.0,                0.0, -2.0 / 2000, 0.0,
			             -1.0,                1.0,         0.0, 1.0
		]));

		bitmapRenderTransform = new Matrix3D();
		bitmapRenderTransform.identity();
		// bitmapRenderTransform.append(bitmapTransform);
		bitmapRenderTransform.append(projectionTransform);

		// 4 is the size of each vertex, in bytes
		vBuffer = ctx.createVertexBuffer(vCount, vertexSize32);
		iBuffer = ctx.createIndexBuffer(iCount);
	}

	public function render(ctx:Context3D)
	{
		ctx.setProgram(program);
		// ctx.setBlendFactors(ONE, ONE_MINUS_SOURCE_ALPHA); // IDK YET

		ctx.setTextureAt(0, bm1Texture);
		ctx.setTextureAt(1, bm2Texture);

		ctx.setSamplerStateAt(0, REPEAT, NEAREST, MIPNONE);
		ctx.setSamplerStateAt(1, REPEAT, NEAREST, MIPNONE);

		var uidx = program.getConstantIndex("projection");
		ctx.setProgramConstantsFromMatrix(VERTEX, uidx, bitmapRenderTransform, false);
		ctx.setVertexBufferAt(program.getAttributeIndex("in_pos"), vBuffer, 0, FLOAT_2);
		ctx.setVertexBufferAt(program.getAttributeIndex("in_uv"), vBuffer, 2, FLOAT_2);

		// vBuffer.uploadFromVector(vertices, 0, maxGlyphCount * 4);
		// iBuffer.uploadFromVector(indices, 0, maxGlyphCount * 6);
		vBuffer.uploadFromVector(vertices, 0, glyphCount * 4);
		iBuffer.uploadFromVector(indices, 0, glyphCount * 6);
		ctx.drawTriangles(iBuffer, 0, glyphCount * 2);

		ctx.present();
	}
}
