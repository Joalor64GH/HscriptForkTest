package;

import flixel.text.FlxText;
import flixel.FlxState;
import flixel.FlxG;

import ModHandler;
import Hscript;

class PlayState extends FlxState {
	public static var instance:PlayState = null;
	public var scriptArray:Array<Hscript> = [];

	override public function create() {
		super.create();

		instance = this;

		ModHandler.reload();

		var text = new FlxText(0, 0, 0, "Hello World", 64);
		text.screenCenter();
		add(text);

		var foldersToCheck:Array<String> = [Paths.file('data/')];
		#if FUTURE_POLYMOD
		for (mod in ModHandler.getModIDs())
			foldersToCheck.push('mods/' + mod + '/data/');
		#end
		for (folder in foldersToCheck) {
			if (FileSystem.exists(folder) && FileSystem.isDirectory(folder)) {
				for (file in FileSystem.readDirectory(folder)) {
					if (file.endsWith('.hxs')) {
						scriptArray.push(new Hscript(folder + file));
					}
				}
			}
		}

		for (script in scriptArray) {
			script?.setVariable('addScript', function(path:String) {
				scriptArray.push(new Hscript('$path.hxs'));
			});
		}
	}

	override public function update(elapsed:Float) {
		callOnScripts('update', [elapsed]);
		super.update(elapsed);
	}

	override public function destroy() {
		callOnScripts('destroy', []);
		super.destroy();

		for (script in scriptArray)
			script?.destroy();
		scriptArray = [];
	}

	private function callOnScripts(funcName:String, args:Array<Dynamic>):Dynamic {
		var value:Dynamic = Hscript.Function_Continue;

		for (i in 0...scriptArray.length) {
			final call:Dynamic = scriptArray[i].executeFunc(funcName, args);
			final bool:Bool = call == Hscript.Function_Continue;
			if (!bool && call != null)
				value = call;
		}

		return value;
	}
}