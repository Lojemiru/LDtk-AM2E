package data.def;

import data.DataTypes;

class BackgroundDef {
	var _project : data.Project;

	@:allow(data.Definitions)
	public var uid(default,null) : Int;
	public var identifier(default,set) : String;


}