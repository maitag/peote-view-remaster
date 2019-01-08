package;

#if sampleGLPicking
import haxe.Timer;

import lime.ui.Window;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;

import peote.view.PeoteGL;
import peote.view.PeoteView;
import peote.view.Display;
import peote.view.Buffer;
import peote.view.Program;
import peote.view.Color;
import peote.view.Element;
//import peote.view.Texture;

class Elem implements Element
{
	@posX public var x:Int=0; // signed 2 bytes integer
	@posY public var y:Int=0; // signed 2 bytes integer
	
	@sizeX public var w:Int=100;
	@sizeY public var h:Int=100;
	
	@color public var c:Color = 0xff0000ff;
		
	@zIndex public var z:Int = 0;	
	
	public function new(positionX:Int=0, positionY:Int=0, width:Int=100, height:Int=100, c:Int=0xff0000ff )
	{
		this.x = positionX;
		this.y = positionY;
		this.w = width;
		this.h = height;
		this.c = c;
	}
	
	var OPTIONS = { picking:true, texRepeatX:true };

}

class GLPicking 
{
	var peoteView:PeoteView;

	var element:Elem;
	var buffer:Buffer<Elem>;
	var displayLeft:Display;
	var displayRight:Display; 
	var programLeft:Program;
	var programRight:Program; 
	
	public function new(window:Window)
	{	

		//peoteView = new PeoteView(window.context, window.width, window.height, Color.GREY1);
		peoteView = new PeoteView(window.context, window.width, window.height, Color.GREEN);
		
		displayLeft  = new Display(0, 0, 280, 280, Color.BLUE);
		displayRight = new Display(300, 0, 280, 280, Color.YELLOW);
		
		peoteView.zoom = 1.0;
		peoteView.xOffset = 0;
		peoteView.yOffset = 0;
		
		peoteView.addDisplay(displayLeft);
		peoteView.addDisplay(displayRight);
		
		buffer   = new Buffer<Elem>(100);

		element  = new Elem(0, 0);
		buffer.addElement(element);

		
		programLeft  = new Program(buffer);
		programRight = new Program(buffer);
		
		displayLeft.addProgram(programLeft);
		displayRight.addProgram(programRight);
		
		
		
		var timer = new Timer(60);
		timer.run =  function() {
			//element.x++; buffer.updateElement(element);
			if (element.x > 170) timer.stop();
		};
		
		
	}

	public function onMouseDown (x:Float, y:Float, button:MouseButton):Void
	{
		// TODO
		// TODO
		// TODO
		//var pickedElement = buffer.pickElementAt(Std.int(x), Std.int(y), programLeft);
		var pickedElement = peoteView.getElementAt(Std.int(x), Std.int(y), displayLeft, programLeft);
		trace(pickedElement);
		//if (pickedElement != null) pickedElement.y += 100;
	}
	
	public function onKeyDown (keyCode:KeyCode, modifier:KeyModifier):Void
	{
		var steps = 10;
		var esteps = element.w;
		switch (keyCode) {
			case KeyCode.LEFT:
					if (modifier.ctrlKey) {element.x-=esteps; buffer.updateElement(element);}
					else if (modifier.shiftKey) displayLeft.xOffset-=steps;
					else if (modifier.altKey) displayRight.xOffset-=steps;
					else peoteView.xOffset-=steps;
			case KeyCode.RIGHT:
					if (modifier.ctrlKey) {element.x+=esteps; buffer.updateElement(element);}
					else if (modifier.shiftKey) displayLeft.xOffset+=steps;
					else if (modifier.altKey) displayRight.xOffset+=steps;
					else peoteView.xOffset+=steps;
			case KeyCode.UP:
					if (modifier.ctrlKey) {element.y-=esteps; buffer.updateElement(element);}
					else if (modifier.shiftKey) displayLeft.yOffset-=steps;
					else if (modifier.altKey) displayRight.yOffset-=steps;
					else peoteView.yOffset-=steps;
			case KeyCode.DOWN:
					if (modifier.ctrlKey) {element.y+=esteps; buffer.updateElement(element);}
					else if (modifier.shiftKey) displayLeft.yOffset+=steps;
					else if (modifier.altKey) displayRight.yOffset+=steps;
					else peoteView.yOffset+=steps;
			case KeyCode.NUMPAD_PLUS:
					if (modifier.shiftKey) displayLeft.zoom+=0.25;
					else if (modifier.altKey) displayRight.zoom+=0.25;
					else peoteView.zoom+=0.25;
			case KeyCode.NUMPAD_MINUS:
					if (modifier.shiftKey) displayLeft.zoom-=0.25;
					else if (modifier.altKey) displayRight.zoom-=0.25;
					else peoteView.zoom-=0.25;
			default:
		}
		
	}
	public function update(deltaTime:Int):Void {}
	public function onMouseUp (x:Float, y:Float, button:MouseButton):Void {}
	
	public function render()
	{
		peoteView.render();
	}

	public function resize(width:Int, height:Int)
	{
		peoteView.resize(width, height);
	}

}
#end