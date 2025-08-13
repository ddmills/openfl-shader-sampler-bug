package;

import lime.math.Vector4;
import openfl.Assets;
import openfl.Vector;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.display.FPS;
import openfl.display.Shader;
import openfl.display.Sprite;
import openfl.display.Sprite;
import openfl.display.Tile;
import openfl.display.Tilemap;
import openfl.display.Tileset;
import openfl.display3D.Context3DProgramType;
import openfl.display3D.Context3DTextureFormat;
import openfl.display3D.IndexBuffer3D;
import openfl.display3D.Program3D;
import openfl.display3D.VertexBuffer3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.display3D.textures.Texture;
import openfl.events.Event;
import openfl.geom.Matrix3D;
import openfl.geom.Rectangle;
import openfl.utils.Assets;

class Main extends Sprite
{
	private var bitmapIndexBuffer:IndexBuffer3D;
	private var bitmapRenderTransform:Matrix3D;
	private var bitmapTexture:RectangleTexture;
	private var bitmapTransform:Matrix3D;
	private var bitmapVertexBuffer:VertexBuffer3D;
	private var program:Program3D;
	private var programMatrixUniform:Int;
	private var programTextureAttribute:Int;
	private var programVertexAttribute:Int;
	private var projectionTransform:Matrix3D;
	private var renderTarget:Texture;
	private var bitmap:Bitmap;
	private var glyphs:GlyphBatch;

	public function new()
	{
		super();

		var bm1 = Assets.getBitmapData("assets/cowboy.png");
		var bm2 = Assets.getBitmapData("assets/tocky_8x12.png");
		
		glyphs = new GlyphBatch(bm1, bm2);
		glyphs.createProgram(stage.context3D);

		for (x in 0...50) {
			for (y in 0...50) {
				glyphs.add({
					x: x * 16,
					y: y * 24,
					width: 16,
					height: 24,
					idx: (x + y * 16) % 256,
					texIdx: 0,
					fg1: new Vector4(1, 0, 0, 1),
					fg2: new Vector4(0, 1, 0, 1),
					bg: new Vector4(0, 0, 1, 1),
					outline: new Vector4(1, 0, 1, 1),
				});
			}
		}

		glyphs.clear();

		var fps = new FPS();
		addChild(fps);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(event:Event):Void
	{
		stage.invalidate();
		glyphs.clear();

		for (x in 0...50) {
			for (y in 0...50) {
				glyphs.add({
					x: x * 16,
					y: y * 24,
					width: 16,
					height: 24,
					idx: (x + y * 16) % 256,
					texIdx: 0,
					fg1: new Vector4(1, 0, 0, 1),
					fg2: new Vector4(0, 1, 0, 1),
					bg: new Vector4(0, 0, 1, 1),
					outline: new Vector4(1, 0, 1, 1),
				});
			}
		}


		var ctx = stage.context3D;

		glyphs.render(ctx);
	}
}
