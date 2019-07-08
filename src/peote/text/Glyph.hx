package peote.text;

#if !macro
@:genericBuild(peote.text.Glyph.GlyphMacro.build())
class Glyph<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

class GlyphMacro
{
	public static var cache = new Map<String, Bool>();
	
	static public function build()
	{	
		switch (Context.getLocalType()) {
			case TInst(_, [t]):
				switch (t) {
					case TInst(n, []):
						var g = n.get();
						var superName:String = null;
						var superModule:String = null;
						var s = g;
						while (s.superClass != null) {
							s = s.superClass.t.get(); //trace("->" + s.name);
							superName = s.name;
							superModule = s.module;
						}
						// TODO:
						//var missInterface = true;
						//if (s.interfaces != null) for (i in s.interfaces) if (i.t.get().module == "peote.view.Element") missInterface = false;
						//if (missInterface) throw Context.error('Error: Type parameter for FontProgram need to be generated by implementing "peote.view.Element"', Context.currentPos());
						
						return buildClass("Glyph",  g.pack, g.module, g.name, superModule, superName, TypeTools.toComplexType(t) );
					case t: Context.error("Class expected", Context.currentPos());
				}
			case t: Context.error("Class expected", Context.currentPos());
		}
		return null;
	}
	
	static public function buildClass(className:String, elementPack:Array<String>, elementModule:String, elementName:String, superModule:String, superName:String, elementType:ComplexType):ComplexType
	{		
		className += "_" + elementName;
		var classPackage = Context.getLocalClass().get().pack;
		
		if (!cache.exists(className))
		{
			cache[className] = true;
			
			var elemField:Array<String>;
			if (superName == null) elemField = elementModule.split(".").concat([elementName]);
			else elemField = superModule.split(".").concat([superName]);
			
			#if peoteview_debug_macro
			trace('generating Class: '+classPackage.concat([className]).join('.'));	
			
			trace("ClassName:"+className);           // FontProgram_ElementSimple
			trace("classPackage:" + classPackage);   // [peote,view]	
			
			trace("FontPackage:" + elementPack);  // [elements]
			trace("FontModule:" + elementModule); // elements.ElementSimple
			trace("FontName:" + elementName);     // ElementSimple
			
			trace("FontType:" + elementType);     // TPath({ name => ElementSimple, pack => [elements], params => [] })
			trace("FontField:" + elemField);
			
			#end
			
			var c = macro	
// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------

class $className implements peote.view.Element
{
	public var charcode:Int=0; // TODO: get/set to change the Tile at unicode-range

	@posX public var x:Int=0;
	@posY public var y:Int = 0;
	
	@sizeX @const public var w:Float=16.0;
	@sizeY @const public var h:Float=16.0;
	
	
	public function new(charcode:Int, x:Int, y:Int) 
	{
		this.charcode = charcode;
		this.x = x;
		this.y = y;
	}
	
	public static function setGlobalStyle(program:peote.view.Program, style:peote.text.GlyphStyle) {
		// inject global fontsize and color into shader
		program.setFormula("w", Std.string(style.width));
		program.setFormula("h", Std.string(style.height));
		program.setColorFormula(Std.string(style.color.toGLSL()));
	}
	
}


// -------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------			
			//Context.defineModule(classPackage.concat([className]).join('.'),[c],Context.getLocalImports());
			Context.defineModule(classPackage.concat([className]).join('.'),[c]);
			//Context.defineType(c);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
}
#end

/*package peote.text;

import peote.view.Element;
import peote.view.Program;
import peote.view.Color;


class Glyph implements Element
{
	public var charcode:Int=0; // TODO: get/set to change the Tile at unicode-range

	@posX public var x:Int=0;
	@posY public var y:Int=0;
	
	@sizeX @const public var w:Float=16.0;
	@sizeY @const public var h:Float=16.0;
	
	
	public function new(charcode:Int, x:Int, y:Int) 
	{
		this.charcode = charcode;
		this.x = x;
		this.y = y;
	}
	
	public static function setGlobalStyle(program:Program, style:GlyphStyle) {
		// inject global fontsize and color into shader
		program.setFormula("w", '${style.width}');
		program.setFormula("h", '${style.height}');
		program.setColorFormula('${style.color.toGLSL()}');
	}
	
}
*/