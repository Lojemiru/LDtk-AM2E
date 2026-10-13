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

	public var parallaxX: Float;
	public var parallaxY: Float;

	public var repeatX: Bool;
	public var repeatY: Bool;
	

	public function new(p:Project, uid:Int) {
		_project = p;
		this.uid = uid;
		identifier = "Background"+uid;

        pivotX = 0;
        pivotY = 0;

        parallaxX = 0;
        parallaxY = 0;

        repeatX = true;
        repeatY = true;
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

	public function getImageInfo(pxWid:Int, pxHei:Int) : Null<{ imgData:data.DataTypes.CachedImage, tx:Float, ty:Float, tw:Float, th:Float, dispX:Int, dispY:Int, sx:Float, sy:Float, px:Float, py:Float, repeatX:Bool, repeatY:Bool }> {
		if( !hasImage() )
			return null;

		var data = _project.getOrLoadImage(relPath);
		if( data==null )
			return null;

		var baseTileWid = data.pixels.width;
		var baseTileHei = data.pixels.height;
		var sx = 1.0;
		var sy = 1.0;
		var px = 0.0;
		var py = 0.0;
		switch pos {
			case null:
				throw "pos should not be null";

			case Unscaled:

			case Contain:
				sx = sy = M.fmin( pxWid/baseTileWid, pxHei/baseTileHei );

			case Cover:
				sx = sy = M.fmax( pxWid/baseTileWid, pxHei/baseTileHei );

			case CoverDirty:
				sx = pxWid / baseTileWid;
				sy = pxHei/ baseTileHei;

			case Repeat:
				// Do nothing, tiling shenanigans are handled in createBgTiledTexture.

			case Parallax:
				// ahhhhhhh
				px = parallaxX;
				py = parallaxY;

		}

		// Crop tile
		var subTileWid = M.fmin(baseTileWid, pxWid/sx);
		var subTileHei = M.fmin(baseTileHei, pxHei/sy);

		return {
			imgData: data,
			tx: pivotX * (baseTileWid-subTileWid),
			ty: pivotY * (baseTileHei-subTileHei),
			tw: subTileWid,
			th: subTileHei,
			dispX: Std.int( pivotX * (pxWid - subTileWid*sx) ),
			dispY: Std.int( pivotY * (pxHei - subTileHei*sy) ),
			sx: sx,
			sy: sy,
			px: px,
			py: py,
			repeatX: repeatX,
			repeatY: repeatY,
		}
	}

	public function toJson() : ldtk.Json.BackgroundDefJson {
		return {
			uid: uid,
			identifier: identifier,
			relPath: relPath,
			pos: JsonTools.writeEnum(pos, true),
			pivotX: JsonTools.writeFloat(pivotX),
			pivotY: JsonTools.writeFloat(pivotY),
			parallaxX: JsonTools.writeFloat(parallaxX),
			parallaxY: JsonTools.writeFloat(parallaxY),
			repeatX: repeatX,
			repeatY: repeatY,
		}
	}

	public static function fromJson(p:Project, json:ldtk.Json.BackgroundDefJson) {
		var bg = new Background( p, data.JsonTools.readInt(json.uid) );

		bg.identifier = JsonTools.readString(json.identifier);
		bg.relPath = json.relPath;
		bg.pos = JsonTools.readEnum(ldtk.Json.BgImagePos, json.pos, true);
		bg.pivotX = JsonTools.readFloat(json.pivotX);
		bg.pivotY = JsonTools.readFloat(json.pivotY);
		bg.parallaxX = JsonTools.readFloat(json.parallaxX, 0);
		bg.parallaxY = JsonTools.readFloat(json.parallaxY, 0);
		bg.repeatX = JsonTools.readBool(json.repeatX, true);
		bg.repeatY = JsonTools.readBool(json.repeatY, true);

		return bg;
	}
}