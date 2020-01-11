package peote.text;

#if !macro
@:genericBuild(peote.text.FontProgram.FontProgramMacro.build())
class FontProgram<T> {}
#else

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

class FontProgramMacro
{
	public static var cache = new Map<String, Bool>();
	
	static public function build()
	{	
		switch (Context.getLocalType()) {
			case TInst(_, [t]):
				switch (t) {
					case TInst(n, []):
						var style = n.get();
						var styleSuperName:String = null;
						var styleSuperModule:String = null;
						var s = style;
						while (s.superClass != null) {
							s = s.superClass.t.get(); trace("->" + s.name);
							styleSuperName = s.name;
							styleSuperModule = s.module;
						}
						return buildClass(
							"FontProgram", style.pack, style.module, style.name, styleSuperModule, styleSuperName, TypeTools.toComplexType(t)
						);	
					default: Context.error("Type for GlyphStyle expected", Context.currentPos());
				}
			default: Context.error("Type for GlyphStyle expected", Context.currentPos());
		}
		return null;
	}
	
	static public function buildClass(className:String, stylePack:Array<String>, styleModule:String, styleName:String, styleSuperModule:String, styleSuperName:String, styleType:ComplexType):ComplexType
	{		
		var styleMod = styleModule.split(".").join("_");
		
		className += "__" + styleMod;
		if (styleModule.split(".").pop() != styleName) className += ((styleMod != "") ? "_" : "") + styleName;
		
		var classPackage = Context.getLocalClass().get().pack;
		
		if (!cache.exists(className))
		{
			cache[className] = true;
			
			var styleField:Array<String>;
			//if (styleSuperName == null) styleField = styleModule.split(".").concat([styleName]);
			//else styleField = styleSuperModule.split(".").concat([styleSuperName]);
			styleField = styleModule.split(".").concat([styleName]);
			
			var glyphType = Glyph.GlyphMacro.buildClass("Glyph", stylePack, styleModule, styleName, styleSuperModule, styleSuperName, styleType);
			
			#if peoteview_debug_macro
			trace('generating Class: '+classPackage.concat([className]).join('.'));	
			
			trace("ClassName:"+className);           // FontProgram__peote_text_GlypStyle
			trace("classPackage:" + classPackage);   // [peote,text]	
			
			trace("StylePackage:" + stylePack);  // [peote.text]
			trace("StyleModule:" + styleModule); // peote.text.GlyphStyle
			trace("StyleName:" + styleName);     // GlyphStyle			
			trace("StyleType:" + styleType);     // TPath(...)
			trace("StyleField:" + styleField);   // [peote,text,GlyphStyle,GlyphStyle]
			#end
			
			var glyphStyleHasMeta = Glyph.GlyphMacro.parseGlyphStyleMetas(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasMeta", glyphStyleHasMeta);
			var glyphStyleHasField = Glyph.GlyphMacro.parseGlyphStyleFields(styleModule+"."+styleName); // trace("FontProgram: glyphStyleHasField", glyphStyleHasField);
			
			var charDataType:ComplexType;
			if (glyphStyleHasMeta.packed) {
				if (glyphStyleHasMeta.multiTexture && glyphStyleHasMeta.multiSlot) charDataType = macro: {unit:Int, slot:Int, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
				else if (glyphStyleHasMeta.multiTexture) charDataType = macro: {unit:Int, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
				else if (glyphStyleHasMeta.multiSlot) charDataType = macro: {slot:Int, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
				else charDataType = macro: {fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric};
			}
			else  {
				if (glyphStyleHasMeta.multiTexture && glyphStyleHasMeta.multiSlot) charDataType = macro: {unit:Int, slot:Int, min:Int, max:Int};
				else if (glyphStyleHasMeta.multiTexture) charDataType = macro: {unit:Int, min:Int, max:Int};
				else if (glyphStyleHasMeta.multiSlot) charDataType = macro: {slot:Int, min:Int, max:Int};
				else charDataType = macro: {min:Int, max:Int};
			}

			// -------------------------------------------------------------------------------------------
			var c = macro		

			class $className extends peote.view.Program
			{
				public var font:peote.text.Font<$styleType>; // TODO peote.text.Font<$styleType>
				public var fontStyle:$styleType;
				
				public var penX:Float = 0.0;
				public var penY:Float = 0.0;
				
				var prev_charcode = -1;
				
				var _buffer:peote.view.Buffer<$glyphType>;
				
				public function new(font:peote.text.Font<$styleType>, fontStyle:$styleType)
				{
					_buffer = new peote.view.Buffer<$glyphType>(100);
					super(_buffer);	
					
					setFont(font);
					setFontStyle(fontStyle);
				}
				
				public inline function addGlyph(glyph:$glyphType, charcode:Int, x:Null<Float>=null, y:Null<Float>=null, glyphStyle:$styleType = null):Bool {
					glyphSetStyle(glyph, glyphStyle);
					if (setCharcode(glyph, charcode, x, y)) {
						_buffer.addElement(glyph);
						return true;
					} else return false;
				}
								
				public inline function removeGlyph(glyph:$glyphType):Void {
					_buffer.removeElement(glyph);
				}
								
				public inline function updateGlyph(glyph:$glyphType):Void {
					_buffer.updateElement(glyph);
				}
				
				public inline function glyphSetStyle(glyph:$glyphType, glyphStyle:$styleType) {
					glyph.setStyle((glyphStyle != null) ? glyphStyle : fontStyle);
				}

				public inline function glyphSetChar(glyph:$glyphType, charcode:Int, x:Null<Float>=null, y:Null<Float>=null):Bool
				{
					return setCharcode(glyph, charcode, x, y, true);
				}

				// -------------------------------------------------
								
				inline function setXW(glyph:$glyphType, charcode:Int, x:Null<Float>, width:Float, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric):Void {
					${switch (glyphStyleHasMeta.packed)
					{	case true: macro // ------- Gl3Font -------
						{
							glyph.w = metric.width * width;
							if (x == null) {
								if (font.kerning && prev_charcode != -1) { // KERNING
									penX += fontData.kerning[prev_charcode][charcode] * width;
								}
								prev_charcode = charcode;
								glyph.x = penX + metric.left * width;
								penX += metric.advance * width;
							}
						}
						default: macro {}
					}}
				}
								
				inline function setYW(glyph:$glyphType, charcode:Int, y:Null<Float>, height:Float, fontData:peote.text.Gl3FontData, metric:peote.text.Gl3FontData.Metric):Void {
					${switch (glyphStyleHasMeta.packed)
					{	case true: macro // ------- Gl3Font -------
						{
							glyph.h = metric.height * height;
							if (y == null) {
								glyph.y = penY + (fontData.height + fontData.descender - metric.top) * height;
							}					
						}
						default: macro {}
					}}
				}
				
				// -------------------------------------------------
				
				inline function setXWsimple(glyph:$glyphType, charcode:Int, x:Null<Float>, width:Float):Void {
					${switch (glyphStyleHasField.local_width) {
						case true: macro {
							glyph.width = width;
						}
						default: macro {}
					}}
					if (x == null) {
						glyph.x = penX;
						penX += width - width/font.config.width*(font.config.paddingRight-font.config.paddingLeft); // TODO: letterSpacing
					}					
				}
								
				inline function setYWsimple(glyph:$glyphType, charcode:Int, y:Null<Float>, height:Float):Void {
					${switch (glyphStyleHasField.local_height) {
						case true: macro {
							glyph.height = height;
						}
						default: macro {}
					}}
					if (y == null) {
						glyph.y = penY;
					}					
				}

				// -------------------------------------------------
				
				inline function rightGlyphPos(glyph:$glyphType):Float
				{
					${switch (glyphStyleHasMeta.packed)
					{
						case true: macro // ------- Gl3Font -------
						{
							var range = font.getRange(glyph.char);
							var metric:peote.text.Gl3FontData.Metric = null;
							var fontData:Gl3FontData = null;
							
							${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
								case true: macro {
									if (range != null) {
										fontData = range.fontData;
										metric = fontData.getMetric(glyph.char);
									}
								}
								default: macro {
									fontData = range;
									metric = fontData.getMetric(glyph.char);
								}
							}}
							var width = ${switch (glyphStyleHasField.local_width) {
								case true: macro glyph.width;
								default: switch (glyphStyleHasField.width) {
									case true: macro fontStyle.width;
									default: macro font.config.width;
							}}}
							return glyph.x + (metric.advance - metric.left) * width;
						}
						default: macro // ------- simple font -------
						{
							return glyph.x + glyph.width;
						}
					}}
					
				}
				
				inline function leftGlyphPos(glyph:$glyphType, prevCharcode:Int):Float
				{
					${switch (glyphStyleHasMeta.packed)
					{
						case true: macro // ------- Gl3Font -------
						{
							var range = font.getRange(glyph.char);
							var metric:peote.text.Gl3FontData.Metric = null;
							var fontData:Gl3FontData = null;
							
							${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
								case true: macro {
									if (range != null) {
										fontData = range.fontData;
										metric = fontData.getMetric(glyph.char);
									}
								}
								default: macro {
									fontData = range;
									metric = fontData.getMetric(glyph.char);
								}
							}}
							var width = ${switch (glyphStyleHasField.local_width) {
								case true: macro glyph.width;
								default: switch (glyphStyleHasField.width) {
									case true: macro fontStyle.width;
									default: macro font.config.width;
							}}}
							var left = glyph.x - (metric.left) * width;
							if (font.kerning && prev_charcode != -1) left -= fontData.kerning[prevCharcode][glyph.char] * width;
							return left;
							
						}
						default: macro // ------- simple font -------
						{
							return glyph.x;
						}
					}}
					
				}
				
				inline function getLineMetric(glyph:$glyphType): {asc:Float, base:Float, desc:Float}
				{
					${switch (glyphStyleHasMeta.packed)
					{
						case true: macro // ------- Gl3Font -------
						{
							var range = font.getRange(glyph.char);
							//var metric:peote.text.Gl3FontData.Metric = null;
							var fontData:Gl3FontData = null;
							
							${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
								case true: macro {
									if (range != null) {
										fontData = range.fontData;
										//metric = fontData.getMetric(glyph.char);
									}
								}
								default: macro {
									fontData = range;
									//metric = fontData.getMetric(glyph.char);
								}
							}}
							var height = ${switch (glyphStyleHasField.local_height) {
								case true: macro glyph.height;
								default: switch (glyphStyleHasField.height) {
									case true: macro fontStyle.height;
									default: macro font.config.height;
							}}}
							return {
								asc: height *(fontData.height + fontData.descender - (1 + fontData.ascender - fontData.height)),
								base:height *(fontData.height + fontData.descender),
								desc:height * fontData.height
							};
							
						}
						default: macro // ------- simple font -------
						{
							return null; // TODO: baseline from fontconfig!!!
						}
					}}
					
				}
				
				// returns range, fontdata and metric dependend of font-type
				inline function getCharData(charcode:Int):$charDataType 
				{
					${switch (glyphStyleHasMeta.packed) {
						// ------- Gl3Font -------
						case true: 
							if (glyphStyleHasMeta.multiTexture && glyphStyleHasMeta.multiSlot) {
								macro {
									var range = font.getRange(charcode);
									if (range != null) {
										var metric = range.fontData.getMetric(charcode);
										if (metric == null) return null;
										else return {unit:range.unit, slot:range.slot, fontData:range.fontData, metric:metric};
									}
									else return null;
								}
							}
							else if (glyphStyleHasMeta.multiTexture) 
								macro {
									var range = font.getRange(charcode);
									if (range != null) {
										var metric = range.fontData.getMetric(charcode);
										if (metric == null) return null;
										else return {unit:range.unit, fontData:range.fontData, metric:metric};
									}
									else return null;
								}
							else if (glyphStyleHasMeta.multiSlot)
								macro {
									var range = font.getRange(charcode);
									if (range != null) {
										var metric = range.fontData.getMetric(charcode);
										if (metric == null) return null;
										else return {slot:range.slot, fontData:range.fontData, metric:metric};
									}
									else return null;
								}
							else macro {
									var metric = font.getRange(charcode).getMetric(charcode);
									if (metric == null) return null;
									else return {fontData:font.getRange(charcode), metric:metric};
								}
						// ------- simple font -------
						default:macro return font.getRange(charcode);
					}}
				}
				
				// TODO: split into getFontData(charcode:Int), setCharcode and setPosition
				// TODO: penX should be local into Line
				inline function setCharcode(glyph:$glyphType, charcode:Int, x:Null<Float>=null, y:Null<Float>=null, isNewChar = true):Bool
				{
					if (isNewChar) glyph.char = charcode;
					if (x != null) glyph.x = x;
					if (y != null) glyph.y = y;
					
					${switch (glyphStyleHasMeta.packed)
					{
						case true: macro // ------- Gl3Font -------
						{
							var range = font.getRange(charcode);
							var metric:peote.text.Gl3FontData.Metric = null;
							var fontData:Gl3FontData = null;
							
							${switch (glyphStyleHasMeta.multiTexture || glyphStyleHasMeta.multiSlot) {
								case true: macro {
									if (range != null) {
										${switch (glyphStyleHasMeta.multiTexture) {
											case true: macro glyph.unit = range.unit;
											default: macro {}
										}}
										${switch (glyphStyleHasMeta.multiSlot) {
											case true: macro glyph.slot = range.slot;
											default: macro {}
										}}
										fontData = range.fontData;
										metric = fontData.getMetric(charcode);
									}
								}
								default: macro {
									fontData = range;
									metric = fontData.getMetric(charcode);
								}
							}}
							
							if (metric != null) {
								if (isNewChar) {
									// TODO: let glyphes-width also include metrics with tex-offsets on need
									glyph.tx = metric.u; // TODO: offsets for THICK letters
									glyph.ty = metric.v;
									glyph.tw = metric.w;
									glyph.th = metric.h;
								}
								${switch (glyphStyleHasField.local_width) {
									case true: macro setXW(glyph, charcode, x, glyph.width, fontData, metric);
									default: switch (glyphStyleHasField.width) {
										case true: macro setXW(glyph, charcode, x, fontStyle.width, fontData, metric);
										default: macro setXW(glyph, charcode, x, font.config.width, fontData, metric);
								}}}
								${switch (glyphStyleHasField.local_height) {
									case true: macro setYW(glyph, charcode, y, glyph.height, fontData, metric);
									default: switch (glyphStyleHasField.height) {
										case true: macro setYW(glyph, charcode, y, fontStyle.height, fontData, metric);
										default: macro setYW(glyph, charcode, y, font.config.height, fontData, metric);
								}}}
								return true;
							}
							else return false;
							
						}
						default: macro // ------- simple font -------
						{
							if (isNewChar)
							{
								var range = font.getRange(charcode);
								if (range != null)
								{
									${switch (glyphStyleHasMeta.multiTexture) {
										case true: macro glyph.unit = range.unit;
										default: macro {}
									}}
									${switch (glyphStyleHasMeta.multiSlot) {
										case true: macro glyph.slot = range.slot;
										default: macro {}
									}}						
									glyph.tile = charcode-range.min;
									
									${switch (glyphStyleHasField.local_width) {
										case true: macro setXWsimple(glyph, charcode, x, glyph.width);
										default: switch (glyphStyleHasField.width) {
											case true: macro setXWsimple(glyph, charcode, x, fontStyle.width);
											default: macro setXWsimple(glyph, charcode, x, font.config.width);
									}}}
									${switch (glyphStyleHasField.local_height) {
										case true: macro setYWsimple(glyph, charcode, y, glyph.height);
										default: switch (glyphStyleHasField.height) {
											case true: macro setYWsimple(glyph, charcode, y, fontStyle.height);
											default: macro setYWsimple(glyph, charcode, y, font.config.height);
									}}}
									
									return true;
								} 
								else return false;
							}
							else {
								${switch (glyphStyleHasField.local_width) {
									case true: macro setXWsimple(glyph, charcode, x, glyph.width);
									default: switch (glyphStyleHasField.width) {
										case true: macro setXWsimple(glyph, charcode, x, fontStyle.width);
										default: macro setXWsimple(glyph, charcode, x, font.config.width);
								}}}
								${switch (glyphStyleHasField.local_height) {
									case true: macro setYWsimple(glyph, charcode, y, glyph.height);
									default: switch (glyphStyleHasField.height) {
										case true: macro setYWsimple(glyph, charcode, y, fontStyle.height);
										default: macro setYWsimple(glyph, charcode, y, font.config.height);
								}}}
								
								return true;
							}
							
						}
					}}
				
				}

				
				public inline function setFont(font:Font<$styleType>):Void
				{
					this.font = font;
					autoUpdateTextures = false;

					${switch (glyphStyleHasMeta.multiTexture) {
						case true: macro setMultiTexture(font.textureCache.textures, "TEX");
						default: macro setTexture(font.textureCache, "TEX");
					}}
				}
				
				public inline function setFontStyle(fontStyle:$styleType):Void
				{
					this.fontStyle = fontStyle;
					
					var color:String;
					${switch (glyphStyleHasField.local_color) {
						case true: macro color = "color";
						default: switch (glyphStyleHasField.color) {
							case true: macro color = Std.string(fontStyle.color.toGLSL());
							default: macro color = Std.string(font.config.color.toGLSL());
					}}}
					
					// check distancefield-rendering
					if (font.config.distancefield) {
						var weight = "0.5";
						${switch (glyphStyleHasField.local_weight) {
							case true:  macro weight = "weight";
							default: switch (glyphStyleHasField.weight) {
								case true: macro weight = peote.view.utils.Util.toFloatString(fontStyle.weight);
								default: macro {}
							}
						}}
						var sharp = peote.view.utils.Util.toFloatString(0.5); // TODO
						setColorFormula(color + " * smoothstep( "+weight+" - "+sharp+" * fwidth(TEX.r), "+weight+" + "+sharp+" * fwidth(TEX.r), TEX.r)");							
					}
					else {
						// TODO: bold for no distancefields needs some more spice inside fragmentshader (access to neightboar pixels!)

						// TODO: dirty outline
/*						injectIntoFragmentShader(
						"
							float outline(float t, float threshold, float width)
							{
								return clamp(width - abs(threshold - t) / fwidth(t), 0.0, 1.0);
							}						
						");
						//setColorFormula("mix("+color+" * TEX.r, vec4(1.0,1.0,1.0,1.0), outline(TEX.r, 1.0, 5.0))");							
						//setColorFormula("mix("+color+" * TEX.r, "+color+" , outline(TEX.r, 1.0, 2.0))");							
						//setColorFormula(color + " * mix( TEX.r, 1.0, outline(TEX.r, 0.3, 1.0*uZoom) )");							
						//setColorFormula("mix("+color+"*TEX.r, vec4(1.0,1.0,0.0,1.0), outline(TEX.r, 0.0, 1.0*uZoom) )");							
*/						
						setColorFormula(color + " * TEX.r");							
					}

					alphaEnabled = true;
					
					${switch (glyphStyleHasField.zIndex && !glyphStyleHasField.local_zIndex) {
						case true: macro setFormula("zIndex", peote.view.utils.Util.toFloatString(fontStyle.zIndex));
						default: macro {}
					}}
					
					${switch (glyphStyleHasField.rotation && !glyphStyleHasField.local_rotation) {
						case true: macro setFormula("rotation", peote.view.utils.Util.toFloatString(fontStyle.rotation));
						default: macro {}
					}}
					

					var tilt:String = "0.0";
					${switch (glyphStyleHasField.local_tilt) {
						case true:  macro tilt = "tilt";
						default: switch (glyphStyleHasField.tilt) {
							case true: macro tilt = peote.view.utils.Util.toFloatString(fontStyle.tilt);
							default: macro {}
						}
					}}
					
					
					${switch (glyphStyleHasMeta.packed)
					{
						case true: macro // ------- packed -------
						{
							// tilting
							if (tilt != "0.0") setFormula("x", "x + (1.0-aPosition.y)*w*" + tilt);
						}
						default: macro // ------- simple font -------
						{
							// make width/height constant if global
							${switch (glyphStyleHasField.local_width) {
								case true: macro {}
								default: switch (glyphStyleHasField.width) {
									case true:
										macro setFormula("width", peote.view.utils.Util.toFloatString(fontStyle.width));
									default:
										macro setFormula("width", peote.view.utils.Util.toFloatString(font.config.width));
							}}}
							${switch (glyphStyleHasField.local_height) {
								case true: macro {}
								default: switch (glyphStyleHasField.height) {
									case true:
										macro setFormula("height", peote.view.utils.Util.toFloatString(fontStyle.height));
									default:
										macro setFormula("height", peote.view.utils.Util.toFloatString(font.config.height));
							}}}
							
							// mixing alpha while use of zIndex
							${switch (glyphStyleHasField.zIndex) {
								case true: macro {discardAtAlpha(0.5);}
								default: macro {}
							}}
							
							if (tilt != "" && tilt != "0.0") setFormula("x", "x + (1.0-aPosition.y)*width*" + tilt);
							
						}
						
					}}
					
					updateTextures();
				}
				
				// -----------------------------------------
				// ---------------- Lines ------------------
				// -----------------------------------------
				public function addLine(line:Line<$styleType>, chars:String, x:Float=0, y:Float=0, glyphStyle:$styleType = null)
				{
					// TODO: add/remove withouth loosing the glyphes
					
					trace("addLine");
					penX = line.x = x;
					penY = line.y = y;
					var first = true;
					haxe.Utf8.iter(chars, function(charcode)
					{
						//trace(penX);
						var glyph = new Glyph<$styleType>();
						line.glyphes.push(glyph);
						addGlyph(glyph, charcode, glyphStyle);	// TODO: separate function to get metric first
						
						if (first) {
							first = false;
							var lm = getLineMetric(glyph);
							line.ascender = lm.asc;
							line.height = lm.desc;
							line.base = lm.base;
						}
						//trace(String.fromCharCode(line.chars[line.chars.length-1]),line.glyphes[line.chars.length-1].x);
					});
					//trace("line metric:", line.height, line.base);
				}
				
				public function removeLine(line:Line<$styleType>)
				{
					for (glyph in line.glyphes) {
						removeGlyph(glyph);
					}
				}
				
				// ----------- change Line Style and Position ----------------
				
				public function lineSetStyle(line:Line<$styleType>, glyphStyle:$styleType, from:Int = 0, to:Null<Int> = null)
				{
					if (to == null) to = line.glyphes.length;
					
					if (from < line.updateFrom) line.updateFrom = from;
					if (to > line.updateTo) line.updateTo = to;
					
					if (from == 0) {
						penX = line.x;
						prev_charcode = -1;
					}
					else {
						penX = rightGlyphPos(line.glyphes[from - 1]);
						prev_charcode = line.glyphes[from - 1].char;
					}
						
					for (i in from...to) {
						line.glyphes[i].setStyle(glyphStyle);
						_lineSetCharcode(i, line, false, (i == to - 1 && i + 1 < line.glyphes.length));
					}
					
				}
				
				inline function _lineSetCharcode (i:Int, line:Line<$styleType>, isNewChar:Bool = true, isLast:Bool = true):Bool {
					// TODO: callback if line height is changing
					// this also not need for every char in loops !
					penY = line.y;
					var lm = getLineMetric(line.glyphes[i]);
					if (line.height != lm.desc) { // TODO: return metric from setCharcode() or integrate metric into glyph
						penY = line.y + (line.base - lm.base);
						//trace("line metric new style:", penY, line.height, line.base);
					}
					
					if (setCharcode(line.glyphes[i], line.glyphes[i].char, isNewChar))
					{
						if (isLast) // last
						{
							var offset = penX - leftGlyphPos(line.glyphes[i+1], (font.kerning) ? line.glyphes[i].char : -1);
							if (offset != 0.0) {
								//trace("REST:"+String.fromCharCode(line.chars[i + 1]), penX, line.glyphes[i + 1].x);
								_setLinePositionOffset(line, offset, 0, i + 1, line.glyphes.length);
								line.updateTo = line.glyphes.length;
							}
						}
						return true;
					} else return false;
				}
						
				public function lineSetPosition(line:Line<$styleType>, xNew:Float, yNew:Float)
				{
					_setLinePositionOffset(line, xNew - line.x, yNew - line.y, 0, line.glyphes.length); 
					line.x = xNew;
					line.y = yNew;
					line.updateFrom = 0;
					line.updateTo = line.glyphes.length;
				}
				
				inline function _setLinePositionOffset(line:Line<$styleType>, deltaX:Float, deltaY:Float, from:Int, to:Int)
				{
					if (deltaX == 0)
						for (i in from...to) line.glyphes[i].y += deltaY;
					else if (deltaY == 0)
						for (i in from...to) line.glyphes[i].x += deltaX;
					else 
						for (i in from...to) {
							line.glyphes[i].x += deltaX;
							line.glyphes[i].y += deltaY;
						}
				}
				
				// ------------ set/insert/delete chars from a line ---------------
				
				public function lineSetChar(line:Line<$styleType>, charcode:Int, position:Int=0, glyphStyle:$styleType = null):Bool
				{
					if (position < line.updateFrom) line.updateFrom = position;
					if (position + 1 > line.updateTo) line.updateTo = position + 1;
					
					if (position == 0) {
						penX = line.x;
						prev_charcode = -1;
					}
					else {
						penX = rightGlyphPos(line.glyphes[position - 1]);
						prev_charcode = line.glyphes[position - 1].char;
					}
					line.glyphes[position].char = charcode;
					if (glyphStyle != null) line.glyphes[position].setStyle(glyphStyle);
					return _lineSetCharcode(position, line);					
				}
				
				public function lineSetChars(line:Line<$styleType>, chars:String, position:Int=0, glyphStyle:$styleType = null):Bool
				{
					if (position < line.updateFrom) line.updateFrom = position;
					if (position + chars.length > line.updateTo) line.updateTo = Std.int(Math.min(position + chars.length, line.glyphes.length));
					
					if (position == 0) {
						penX = line.x;
						prev_charcode = -1;
					}
					else {
						penX = rightGlyphPos(line.glyphes[position - 1]);
						prev_charcode = line.glyphes[position - 1].char;
					}
					var i = position;
					var ret = true;
					haxe.Utf8.iter(chars, function(charcode)
					{
						if (i < line.glyphes.length) {
							line.glyphes[i].char = charcode;
							if (glyphStyle != null) line.glyphes[i].setStyle(glyphStyle);
							if (! _lineSetCharcode(i, line, true, (i == position + chars.length - 1 && i + 1 < line.glyphes.length))) ret = false;
						}
						else if (! lineInsertChar(line, charcode, i, glyphStyle)) ret = false; // TODO: optimize if much use of
						i++;
					});
					return ret;
				}
				
				public function lineInsertChar(line:Line<$styleType>, charcode:Int, position:Int = 0, glyphStyle:$styleType = null):Bool
				{
					var glyph = new Glyph<$styleType>();
					glyph.char = charcode;
					glyph.setStyle((glyphStyle != null) ? glyphStyle : fontStyle);

					line.glyphes.insert(position, glyph);
					
					penY = line.y;
					var lm = getLineMetric(glyph);
					if (line.height != lm.desc) { // TODO: separate function to get metric first
						penY = line.y + (line.base - lm.base);
					}
					
					if (position == 0) {
						penX = line.x;
						prev_charcode = -1;
					}
					else {
						penX = rightGlyphPos(line.glyphes[position - 1]);
						prev_charcode = line.glyphes[position - 1].char;
					}
					var startPenX = penX;
					
					if (setCharcode(glyph, charcode)) {
						_buffer.addElement(glyph);
						if (position + 1 < line.glyphes.length) {
							if (position + 1 < line.updateFrom) line.updateFrom = position + 1;
							line.updateTo = line.glyphes.length;
							_setLinePositionOffset(line, penX - startPenX, 0, position + 1, line.glyphes.length);
						}
						return true;
					} else return false;
				}
				
				public function lineInsertChars(line:Line<$styleType>, chars:String, position:Int = 0, glyphStyle:$styleType = null):Bool 
				{					
					var ret = true;
					var first = true;
					
					if (position == 0) {
						penX = line.x;
						prev_charcode = -1;
					}
					else {
						penX = rightGlyphPos(line.glyphes[position - 1]);
						prev_charcode = line.glyphes[position - 1].char;
					}
					var startPenX = penX;
					
					var rest = line.glyphes.splice(position, line.glyphes.length-position);
					haxe.Utf8.iter(chars, function(charcode)
					{
						var glyph = new Glyph<$styleType>();
						glyph.setStyle((glyphStyle != null) ? glyphStyle : fontStyle);
						line.glyphes.push(glyph);
						if (first) {
							first = false;
							var lm = getLineMetric(glyph);
							if (line.height != lm.desc) { // TODO: separate function to get metric first
								penY = line.y + (line.base - lm.base);
							} else penY = line.y;
						}
						if (setCharcode(glyph, charcode)) {
							_buffer.addElement(glyph);
						} else ret = false;
					
					});
					if (rest.length > 0 && ret) {
						if (line.glyphes.length < line.updateFrom) line.updateFrom = line.glyphes.length;
						line.glyphes = line.glyphes.concat(rest);
						line.updateTo = line.glyphes.length;
						_setLinePositionOffset(line, penX - startPenX, 0, line.glyphes.length - rest.length, line.glyphes.length);
					}
					return ret;
				}
				
				public function lineDeleteChar(line:Line<$styleType>, position:Int = 0)
				{
					removeGlyph(line.glyphes.splice(position, 1)[0]);
					_lineDeleteCharsOffset(line, position, position + 1);
				}
				
				public function lineDeleteChars(line:Line<$styleType>, from:Int = 0, to:Null<Int> = null)
				{
					if (to == null) to = line.glyphes.length;
					for (glyph in line.glyphes.splice(from, to - from)) removeGlyph(glyph);
					_lineDeleteCharsOffset(line, from, to);
				}
				
				inline function _lineDeleteCharsOffset(line:Line<$styleType>, from:Int, to:Int)
				{
					if (from < line.glyphes.length) {
						var offset:Float = 0.0;
						if (from == 0) offset = line.x - leftGlyphPos(line.glyphes[from], -1);
						else offset = rightGlyphPos(line.glyphes[from-1]) - leftGlyphPos(line.glyphes[from], line.glyphes[from-1].char);
						if (from < line.updateFrom) line.updateFrom = from;
						line.updateTo = line.glyphes.length;
						_setLinePositionOffset(line, offset, 0, from, line.glyphes.length);
					}
					else {trace(line.updateFrom, line.updateTo);
						if (line.updateTo > from && line.updateFrom < from) line.updateTo = from;
						else {
							line.updateFrom = 0x1000000;
							line.updateTo = 0;
						}
					}
				}
				
				// ------------- update line ---------------------
				
				public function updateLine(line:Line<$styleType>, from:Null<Int> = null, to:Null<Int> = null)
				{
					if (from != null) line.updateFrom = from;
					if (to != null) line.updateTo = to;
					
					trace("update from "+ line.updateFrom + " to " +line.updateTo);
					for (i in line.updateFrom...line.updateTo) 
						updateGlyph(line.glyphes[i]);

					line.updateFrom = 0x1000000;
					line.updateTo = 0;
				}
			
			} // end class

			// -------------------------------------------------------------------------------------------
			// -------------------------------------------------------------------------------------------
			
			Context.defineModule(classPackage.concat([className]).join('.'),[c]);
		}
		return TPath({ pack:classPackage, name:className, params:[] });
	}
}
#end
