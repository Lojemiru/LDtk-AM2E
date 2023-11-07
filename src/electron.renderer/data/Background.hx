package data;

class Background {
	var _project : data.Project;

	@:allow(data.Definitions, data.def.CompositeBackgroundDef, ui.BackgroundDefsForm)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;

    public var relPath: Null<String>;
	public var pos: Null<ldtk.Json.BgImagePos>;
	public var pivotX: Float;
	public var pivotY: Float;
	

	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		identifier = "Background"+uid;

        pivotX = 0;
        pivotY = 0;
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id, Free);
		if( id==null )
			return identifier;
		else
			return identifier = id;
	}

	public function hasImage() {
		return relPath!=null;
	}

	public function toJson() : ldtk.Json.BackgroundDefJson {
		return {
			uid: uid,
			identifier: identifier,
			relPath: relPath,
			pos: JsonTools.writeEnum(pos, true),
			pivotX: JsonTools.writeFloat(pivotX),
			pivotY: JsonTools.writeFloat(pivotY),
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.BackgroundDefJson) {
		var bg = new Background( p, data.JsonTools.readInt(json.uid) );

		bg.identifier = JsonTools.readString(json.identifier);
		bg.relPath = json.relPath;
		bg.pos = JsonTools.readEnum(ldtk.Json.BgImagePos, json.pos, true);
		bg.pivotX = JsonTools.readFloat(json.pivotX);
		bg.pivotY = JsonTools.readFloat(json.pivotY);

		return bg;
	}
}