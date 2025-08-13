package;

import lime.math.Vector4;
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
	var idx:Int;
	var texIdx:Int;
	var fg1:Vector4;
	var fg2:Vector4;
	var bg:Vector4;
	var outline:Vector4;
}

var vertexSource = "
uniform mat4 projection;

attribute vec2 in_pos;
attribute vec2 in_uv;
attribute vec2 in_indices;
attribute vec4 in_fg1;
attribute vec4 in_fg2;
attribute vec4 in_bg;
attribute vec4 in_outline;

varying vec2 uv;
varying vec2 indices;
varying vec4 fg1;
varying vec4 fg2;
varying vec4 bg;
varying vec4 outline;

void main(void) {
	gl_Position = projection * vec4(in_pos, 0, 1);
	uv = in_uv;
	indices = in_indices;
	fg1 = in_fg1;
	fg2 = in_fg2;
	bg = in_bg;
	outline = in_outline;
}";
var fragmentSource = #if !desktop "precision mediump float;" + #end
"
varying vec2 uv;
varying vec2 indices;
varying vec4 fg1;
varying vec4 fg2;
varying vec4 bg;
varying vec4 outline;

uniform sampler2D sampler_tex_1;
uniform sampler2D sampler_tex_2;

void main(void)
{
	vec2 uv_scaled = uv / 16.0; // atlas is 16x16
	float x = float(uint(indices.x) % 16u);
	float y = float(uint(indices.x) / 16u);
	vec2 uv_offset = vec2(x, y) / 16.0;

	vec2 tex_uv = uv_offset + uv_scaled;

	vec4 v = vec4(0);

	v = texture2D(sampler_tex_1, tex_uv);

	if (v.a == 0) { // transparent (background)
		gl_FragColor = bg;
	} else if (v.r == 0 && v.g == 0 && v.b == 0 && fg1.a > 0) { // Black (Primary)
		gl_FragColor = fg1;
	} else if (v.r == 1 && v.g == 1 && v.b == 1 && fg2.a > 0) { // White (Secondary)
		gl_FragColor = fg2;
	} else if (v.r == 1 && v.g == 0 && v.b == 0 && outline.a > 0) { // Red (Outline)
		gl_FragColor = outline;
	} else { // debug
		gl_FragColor = vec4(1.0, 0.0, 1.0, 1.0);
	}

	if (gl_FragColor.a == 0) {
		discard;
	}
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
		vertices[i++] = (1.0 * g.idx); // idx
		vertices[i++] = (1.0 * g.texIdx); // tex_idx
		vertices[i++] = (g.fg1.x); // fg1.r
		vertices[i++] = (g.fg1.y); // fg1.g
		vertices[i++] = (g.fg1.z); // fg1.b
		vertices[i++] = (g.fg1.w); // fg1.a
		vertices[i++] = (g.fg2.x); // fg2.r
		vertices[i++] = (g.fg2.y); // fg2.g
		vertices[i++] = (g.fg2.z); // fg2.b
		vertices[i++] = (g.fg2.w); // fg2.a
		vertices[i++] = (g.bg.x); // bg.r
		vertices[i++] = (g.bg.y); // bg.g
		vertices[i++] = (g.bg.z); // bg.b
		vertices[i++] = (g.bg.w); // bg.a
		vertices[i++] = (g.outline.x); // outline.r
		vertices[i++] = (g.outline.y); // outline.g
		vertices[i++] = (g.outline.z); // outline.b
		vertices[i++] = (g.outline.w); // outline.a

		vertices[i++] = (g.x + g.width); // x
		vertices[i++] = (g.y); // y
		vertices[i++] = (1); // u
		vertices[i++] = (0); // v
		vertices[i++] = (g.idx); // idx
		vertices[i++] = (g.texIdx); // tex_idx
		vertices[i++] = (g.fg1.x); // fg1.r
		vertices[i++] = (g.fg1.y); // fg1.g
		vertices[i++] = (g.fg1.z); // fg1.b
		vertices[i++] = (g.fg1.w); // fg1.a
		vertices[i++] = (g.fg2.x); // fg2.r
		vertices[i++] = (g.fg2.y); // fg2.g
		vertices[i++] = (g.fg2.z); // fg2.b
		vertices[i++] = (g.fg2.w); // fg2.a
		vertices[i++] = (g.bg.x); // bg.r
		vertices[i++] = (g.bg.y); // bg.g
		vertices[i++] = (g.bg.z); // bg.b
		vertices[i++] = (g.bg.w); // bg.a
		vertices[i++] = (g.outline.x); // outline.r
		vertices[i++] = (g.outline.y); // outline.g
		vertices[i++] = (g.outline.z); // outline.b
		vertices[i++] = (g.outline.w); // outline.a

		vertices[i++] = (g.x + g.width); // x
		vertices[i++] = (g.y + g.height); // y
		vertices[i++] = (1); // u
		vertices[i++] = (1); // v
		vertices[i++] = (g.idx); // idx
		vertices[i++] = (g.texIdx); // tex_idx
		vertices[i++] = (g.fg1.x); // fg1.r
		vertices[i++] = (g.fg1.y); // fg1.g
		vertices[i++] = (g.fg1.z); // fg1.b
		vertices[i++] = (g.fg1.w); // fg1.a
		vertices[i++] = (g.fg2.x); // fg2.r
		vertices[i++] = (g.fg2.y); // fg2.g
		vertices[i++] = (g.fg2.z); // fg2.b
		vertices[i++] = (g.fg2.w); // fg2.a
		vertices[i++] = (g.bg.x); // bg.r
		vertices[i++] = (g.bg.y); // bg.g
		vertices[i++] = (g.bg.z); // bg.b
		vertices[i++] = (g.bg.w); // bg.a
		vertices[i++] = (g.outline.x); // outline.r
		vertices[i++] = (g.outline.y); // outline.g
		vertices[i++] = (g.outline.z); // outline.b
		vertices[i++] = (g.outline.w); // outline.a

		vertices[i++] = (g.x); // x
		vertices[i++] = (g.y + g.height); // y
		vertices[i++] = (0); // u
		vertices[i++] = (1); // v
		vertices[i++] = (g.idx); // idx
		vertices[i++] = (g.texIdx); // tex_idx
		vertices[i++] = (g.fg1.x); // fg1.r
		vertices[i++] = (g.fg1.y); // fg1.g
		vertices[i++] = (g.fg1.z); // fg1.b
		vertices[i++] = (g.fg1.w); // fg1.a
		vertices[i++] = (g.fg2.x); // fg2.r
		vertices[i++] = (g.fg2.y); // fg2.g
		vertices[i++] = (g.fg2.z); // fg2.b
		vertices[i++] = (g.fg2.w); // fg2.a
		vertices[i++] = (g.bg.x); // bg.r
		vertices[i++] = (g.bg.y); // bg.g
		vertices[i++] = (g.bg.z); // bg.b
		vertices[i++] = (g.bg.w); // bg.a
		vertices[i++] = (g.outline.x); // outline.r
		vertices[i++] = (g.outline.y); // outline.g
		vertices[i++] = (g.outline.z); // outline.b
		vertices[i++] = (g.outline.w); // outline.a

		glyphCount++;
	}

	public function clear()
	{
		glyphCount = 0;
	}

	public function createProgram(ctx:Context3D)
	{
		var vCount = 4 * maxGlyphCount;
		var iCount = 6 * maxGlyphCount;

		vertexSize32 = 22;

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
		ctx.setVertexBufferAt(program.getAttributeIndex("in_indices"), vBuffer, 4, FLOAT_2);
		ctx.setVertexBufferAt(program.getAttributeIndex("in_fg1"), vBuffer, 6, FLOAT_4);
		ctx.setVertexBufferAt(program.getAttributeIndex("in_fg2"), vBuffer, 9, FLOAT_4);
		ctx.setVertexBufferAt(program.getAttributeIndex("in_bg"), vBuffer, 12, FLOAT_4);
		ctx.setVertexBufferAt(program.getAttributeIndex("in_outline"), vBuffer, 15, FLOAT_4);

		vBuffer.uploadFromVector(vertices, 0, glyphCount * 4);
		iBuffer.uploadFromVector(indices, 0, glyphCount * 6);
		ctx.drawTriangles(iBuffer, 0, glyphCount * 2);

		ctx.present();
	}
}
