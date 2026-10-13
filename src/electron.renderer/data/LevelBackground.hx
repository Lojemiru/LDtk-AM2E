package data;

class LevelBackground {
    public var relPath: Null<String>;
	public var pos: Null<ldtk.Json.BgImagePos>;
	public var pivotX: Float;
	public var pivotY: Float;

	var level: Level;

	public function new(level:Level) {
        this.level = level;
        pivotX = 0.5;
        pivotY = 0.5;

	}

	// TODO: toJson()
	// TODO: fromJson()
}
