package data.def;

import data.DataTypes;

class CompositeBackgroundDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;

	public var backgrounds : Array<data.Background> = [];

	public var tags : Tags;

	// TODO: toJson()
	// TODO: fromJson()

	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		identifier  = "CompositeBackground"+uid;
		tags = new Tags();
	}

	public function toString() {
		return 'CompositeBackgroundDef.$identifier';
	}

	public function tidy(p:data.Project) {
		_project = p;

		// TODO: tidy things lol
	}

	public function toJson() : ldtk.Json.CompositeBackgroundDefJson {
		return {
			uid: uid,
			identifier: identifier,
			tags: tags.toJson(),
			backgrounds: backgrounds.map( function(bg) return bg.toJson() )
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.CompositeBackgroundDefJson) {
		var td = new CompositeBackgroundDef( p, data.JsonTools.readInt(json.uid) );
		td.tags = Tags.fromJson(json.tags);

		if ( json.backgrounds != null)
			for ( bgJson in JsonTools.readArray(json.backgrounds) )
				td.backgrounds.push( Background.fromJson(p, bgJson) );

		return td;
	}

	function set_identifier(id:String) {
		id = Project.cleanupIdentifier(id, Free);
		if( id==null )
			return identifier;
		else
			return identifier = id;
	}
}