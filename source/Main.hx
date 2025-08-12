package;

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

		var bm = Assets.getBitmapData("assets/cowboy.png");
		
		glyphs = new GlyphBatch(bm);
		glyphs.createProgram(stage.context3D);
		// glyphs.add({
		// 	x: 2,
		// 	y: 3,
		// 	width: 100,
		// 	height: 100,
		// });

		for (x in 0...1000) {
			glyphs.add({
				x: x,
				y: x,
				width: 16 * 32,
				height: 24 * 32,
			});
		}

		var fps = new FPS();
		addChild(fps);
		addEventListener(Event.ENTER_FRAME, onEnterFrame);
	}

	private function onEnterFrame(event:Event):Void
	{
		stage.invalidate();

		var ctx = stage.context3D;

		glyphs.render(ctx);
	}
}
