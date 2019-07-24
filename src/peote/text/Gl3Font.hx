package peote.text;

import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.Json;

import utils.Loader;
import peote.view.PeoteGL.Image;
import peote.view.utils.TextureCache;

class Gl3Font 
{
	var path:String;

	var rangeMapping:Vector<{unit:Int, slot:Int, fontData:Gl3FontData}>;
	public var textureCache:TextureCache;
	var maxTextureSize:Int;
	
	// from json
	var ranges = new Array<{min:Int, max:Int}>();
	var imageNames = new Array<String>();
	var rangeSize = 0x1000;      // amount of unicode range-splitting
	var textureSlotSize = 2048;   // size of textureslot per image in pixels (must match overall image-sizes)
	var kerning = false;
	
	var rParseFolder = new EReg("/*$", "gm");
	
	public function new(fontPath:String, kerning:Bool=true, maxTextureSize:Int=16384) 
	{
		path = rParseFolder.replace(fontPath, '');
		this.kerning = kerning;
		this.maxTextureSize = maxTextureSize;
	}

	public inline function getRange(charcode:Int):{unit:Int, slot:Int, fontData:Gl3FontData}
	{
		return rangeMapping.get(Std.int(charcode/rangeSize));
	}

	// --------------------------- Loading -------------------------

	public function load(?onProgressOverall:Int->Int->Void, onLoad:Void->Void)
	{
		Loader.json(path+"/config.json", true, function(json:Json) {
			
			var rangeSize = Std.parseInt(Reflect.field(json, "rangeSize"));
			if (rangeSize != null) this.rangeSize = rangeSize;
			
			var type = Reflect.field(json, "type");
			if (type != null) if (type != "gl3") throw('Error, type of font "$path/config.json" has to be "gl3"');
			
			var textureSlotSize = Std.parseInt(Reflect.field(json, "textureSlotSize"));
			if (textureSlotSize != null) this.textureSlotSize = textureSlotSize;
			
			if (kerning) {
				var kerning = Reflect.field(json, "kerning");
				if (kerning != null) this.kerning = kerning;
			}
			
			var _ranges = Reflect.field(json, "ranges");
			for( fn in Reflect.fields(_ranges) )
			{
				var r:Array<String> = Reflect.field(_ranges, fn);
				ranges.push({min:Std.parseInt(r[0]), max:Std.parseInt(r[1])});
				imageNames.push(fn);
			}
			
			rangeMapping = new Vector<{unit:Int, slot:Int, fontData:Gl3FontData}>(Std.int(0x1000 * 20 / rangeSize));// TODO: is ( 0x1000 * 20) the greatest charcode for unicode ?
			
			textureCache = new TextureCache(
				[{width:textureSlotSize, height:textureSlotSize, slots:ranges.length}],
				4, // colors -> TODO
				false, // mipmaps
				1,1, // min/mag-filter
				maxTextureSize
			);
		
			loadFontData(onProgressOverall, onLoad);
		});		
	}
	
	private function loadFontData(onProgressOverall:Int->Int->Void, onLoad:Void->Void):Void
	{		
		var gl3FontData = new Array<Gl3FontData>();		
		Loader.bytesArray(
			imageNames.map(function (v) return '$path/$v.dat'),
			true,
			function(index:Int, bytes:Bytes) { // after .dat is loaded
				gl3FontData[index] = new Gl3FontData(bytes, ranges[index].min, ranges[index].max, kerning);	
			},
			function(bytes:Array<Bytes>) { // after all .dat is loaded
				loadImages(gl3FontData, onProgressOverall, onLoad);
			}
		);
	}
	
	public function embed()
	{
		// TODO
	}
	
	private function loadImages(gl3FontData:Array<Gl3FontData>, onProgressOverall:Int->Int->Void, onLoad:Void->Void):Void
	{		
		trace("load images");
		Loader.imageArray(
			imageNames.map(function (v) return '$path/$v.png'),
			true,
			function(index:Int, loaded:Int, size:Int) {
				trace(' loading G3Font-Images progress ' + Std.int(loaded / size * 100) + "%" , ' ($loaded / $size)');
				if (onProgressOverall != null) onProgressOverall(loaded, size);
			},
			function(index:Int, image:Image) { // after every image is loaded
				//trace('File number $index loaded completely.');
				var p = textureCache.addImage(image);
				trace( '${image.width}x${image.height}', "texture-unit:" + p.unit, "texture-slot" + p.slot);
				
				// recalc texture-coords
				var gl3font = gl3FontData[index];
				for (charcode in gl3font.rangeMin...gl3font.rangeMax+1) {
					var m = gl3font.getMetric(charcode);
					if (m != null) {
						m.u *= image.width;
						m.v *= image.height;
						m.w *= image.width;
						m.h *= image.height;
						gl3font.setMetric(charcode, m);
					}
				}
				
				// sort ranges into rangeMapping
				var range = ranges[index];
				for (i in Std.int(range.min / rangeSize)...Std.int(range.max / rangeSize)+1) {
					rangeMapping.set(i, {unit:p.unit, slot:p.slot, fontData:gl3font});
				}
				
			},
			function(images:Array<Image>) { // after all images is loaded
				trace(' --- all images loaded ---');
				onLoad();
			}
		);
		
	}
	
	// --------------------------- Embedding -------------------------
	
	
	
	
}