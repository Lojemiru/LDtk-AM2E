package ui;

import data.Background;

enum BackgroundParentType {
	BP_Background(bg:data.def.CompositeBackgroundDef);
	BP_Level(level:data.Level);
}

class BackgroundDefsForm {
	var editor(get,never) : Editor; inline function get_editor() return Editor.ME;
	var project(get,never) : data.Project; inline function get_project() return Editor.ME.project;
	var curWorld(get,never) : data.World; inline function get_curWorld() return Editor.ME.curWorld;

	var parentType : BackgroundParentType;
	public var jWrapper : js.jquery.JQuery;
	var jList(get,never) : js.jquery.JQuery; inline function get_jList() return jWrapper.find("ul.backgroundList");
	var jForm(get,never) : js.jquery.JQuery; inline function get_jForm() return jWrapper.find("dl.form");
	var jButtons(get,never) : js.jquery.JQuery; inline function get_jButtons() return jList.siblings(".buttons");
	var backgroundDefs : Array<Background>;
	var curBackground : Null<Background>;

	public function new(parentType:BackgroundParentType) {
		this.parentType = parentType;
		this.backgroundDefs = [];

		jWrapper = new J('<div class="backgroundDefsForm"/>');
		jWrapper.html( JsTools.getHtmlTemplate("backgroundDefsForm", { parentType: switch parentType {
			case BP_Background(_): "Background";
			case BP_Level(_): "Level";
		}}) );

		// Create background
		jButtons.find("button.create").click( function(ev) {
			onCreateBackground(ev.getThis());
		});

		JsTools.parseComponents( jButtons );

		updateList();
		updateForm();
	}

	inline function getParentName() {
		return switch parentType {
			case BP_Background(bg): bg!=null ? bg.identifier : "Unknown background";
			case BP_Level(l): l!=null ? l.identifier : "Unknown level";
		}
	}


	inline function isLevelField() {
		return getLevelParent()!=null;
	}
	inline function isBackgroundField() {
		return getBackgroundParent()!=null;
	}

	function getBackgroundParent() {
		return switch parentType {
			case BP_Background(bg): bg;
			case BP_Level(level): null;
		}
	}

	function getLevelParent() {
		return switch parentType {
			case BP_Background(bg): null;
			case BP_Level(level): level;
		}
	}

	public function hide() {
		jWrapper.css({ visibility: "hidden" });
	}

	public function useBackgrounds(parent:BackgroundParentType, backgrounds:Array<Background>) {
		parentType = parent;
		jWrapper.css({ visibility: "visible" });
		backgroundDefs = backgrounds;

		// Default field selection
		var found = false;
		if( curBackground!=null )
			for(f in backgroundDefs)
				if( f.uid==curBackground.uid ) {
					found = true;
					break;
				}
		if( !found )
			selectBackground( backgroundDefs[0] );
	}

	public function selectBackground(bg:Background) {
		curBackground = bg;
		updateList();
		updateForm();
	}

	function updateList() {
		jList.off().empty();

		// List context menu
		ui.modal.ContextMenu.addTo(jList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = pasteBackgroundDef(App.ME.clipboard);
					editor.ge.emit(BackgroundDefAdded(copy));
					selectBackground(copy);
				},
				enable: ()->App.ME.clipboard.is(CBackgroundDef),
			},
		]);

		for(bg in backgroundDefs) {
			var li = new J("<li/>");
			li.appendTo(jList);
			li.append('<span class="name">'+bg.identifier+'</span>');
			if( curBackground==bg )
				li.addClass("active");

			ui.modal.ContextMenu.addTo(li, [
				{
					label: L._Copy(),
					cb: ()->App.ME.clipboard.copyData(CBackgroundDef, bg.toJson()),
				},
				{
					label: L._Cut(),
					cb: ()->{
						App.ME.clipboard.copyData(CBackgroundDef, bg.toJson());
						deleteBackground(bg);
					},
				},
				{
					label: L._PasteAfter(),
					cb: ()->{
						var copy = pasteBackgroundDef(App.ME.clipboard, bg);
						editor.ge.emit(BackgroundDefAdded(copy));
						selectBackground(copy);
					},
					enable: ()->App.ME.clipboard.is(CBackgroundDef),
				},
				{
					label: L._Duplicate(),
					cb:()->{
						var copy = duplicateBackgroundDef(bg);
						editor.ge.emit( BackgroundDefAdded(copy) );
						onAnyChange();
						selectBackground(copy);
					}
				},
				{ label: L._Delete(), cb:()->deleteBackground(bg) },
			]);

			li.click( function(_) selectBackground(bg) );
		}

		
		// Make list sortable
		JsTools.makeSortable(jList, function(ev) {
			var from = ev.oldIndex;
			var to = ev.newIndex;

			if( from<0 || from>=backgroundDefs.length || from==to )
				return;

			if( to<0 || to>=backgroundDefs.length )
				return;

			var moved = backgroundDefs.splice(from,1)[0];
			backgroundDefs.insert(to, moved);

			selectBackground(moved);
			editor.ge.emit( BackgroundDefSorted );
			onAnyChange();
		}, { disableAnim:true });
		

		JsTools.parseComponents(jList);
	}

	function duplicateBackgroundDef(bg:Background) : Background {
		return pasteBackgroundDef( data.Clipboard.createTemp(CBackgroundDef, bg.toJson()), bg );
	}

	function pasteBackgroundDef(c:data.Clipboard, ?after:Background) : Null<Background> {
		if( !c.is(CBackgroundDef) )
			return null;

		var json : ldtk.Json.BackgroundDefJson = c.getParsedJson();
		var copy = Background.fromJson( project, json );
		copy.uid = project.generateUniqueId_int();
		copy.identifier = project.fixUniqueIdStr(json.identifier, Free, (id)->isBackgroundIdentifierUnique(id));
		if( after==null )
			backgroundDefs.push(copy);
		else
			backgroundDefs.insert( dn.Lib.getArrayIndex(after, backgroundDefs)+1, copy );

		project.tidy();
		return copy;
	}

	function deleteBackground(bg:data.Background) {
		new ui.LastChance( L.t._("Background ::name:: deleted", { name:bg.identifier }), project );
		backgroundDefs.remove(bg);
		project.tidy();
		editor.ge.emit( BackgroundDefRemoved(bg) );
		onAnyChange();
		selectBackground( backgroundDefs[0] );
	}

	function isBackgroundIdentifierUnique(id:String, ?except:Background) {
		id = data.Project.cleanupIdentifier(id, Free);
		for(bg in backgroundDefs)
			if( ( except==null || bg!=except ) && bg.identifier==id )
				return false;
		return true;
	}

	function onAnyChange() {
		switch parentType {
			case BP_Background(_):
				for( w in project.worlds )
				for( l in w.levels )
					editor.invalidateLevelCache(l);

			case BP_Level(_):
				for( w in project.worlds )
				for( l in w.levels )
					editor.invalidateLevelCache(l);
				editor.worldRender.invalidateAllLevelFields();
		}
	}

	function updateForm() {
		ui.Tip.clear();
		jForm.find("*").off(); // cleanup events

		if ( curBackground==null ) {
			jForm.css("visibility","hidden");
			return;
		}
		else {
			jForm.css("visibility","visible");
		}

		var i = Input.linkToHtmlInput( curBackground.identifier, jForm.find("input[name=name]") );
		i.onChange = onBackgroundChange;
		i.fixValue = (v)->project.fixUniqueIdStr(v, Free, (id)->isBackgroundIdentifierUnique(id,curBackground));

		// Create bg image picker
		jForm.find("dd.bg .imagePicker").remove();

		var jImg = JsTools.createImagePicker(project, curBackground.relPath, (relPath)->{
			var old = curBackground.relPath;
			if( relPath==null && old!=null ) {
				// Remove
				curBackground.relPath = null;
				//level.bgPos = null;
				editor.watcher.stopWatchingRel( old );
			}
			else if( relPath!=null ) {
				var chk = project.checkImageBeforeLoading(relPath);
				if( chk!=Ok ) {
					ui.modal.dialog.Message.error( L.imageLoadingMessage(relPath, chk) );
					return;
				}

				// Add or update
				var img = project.getOrLoadImage(relPath);
				if( img==null ) {
					ui.modal.dialog.Message.error( L.t._("Could not load this image") );
					return;
				}
				curBackground.relPath = relPath;
				if( old!=null )
					editor.watcher.stopWatchingRel( old );
				editor.watcher.watchImage(relPath);
				if( old==null )
					curBackground.pos = Cover;
			}
			onBackgroundChange();
		});
		jImg.prependTo( jForm.find("dd.bg") );
	
		if( curBackground.hasImage() )
			jForm.find("dd.bg .pos").show();
		else
			jForm.find("dd.bg .pos").hide();

		// Bg position
		var jSelect = jForm.find("#bgPos");
		jSelect.empty();
		if( curBackground.pos!=null ) {
			for(k in ldtk.Json.BgImagePos.getConstructors()) {
				var e = ldtk.Json.BgImagePos.createByName(k);
				var jOpt = new J('<option value="$k"/>');
				jSelect.append(jOpt);
				jOpt.text( switch e {
					case Unscaled: Lang.t._("Not scaled");
					case Contain: Lang.t._("Fit inside (keep aspect ratio)");
					case Cover: Lang.t._("Cover level (keep aspect ratio)");
					case CoverDirty: Lang.t._("Cover (dirty scaling)");
					case Repeat: Lang.t._("Repeat");
					case Parallax: Lang.t._("Parallax");
				});
			}
			jSelect.val( curBackground.pos.getName() );
			jSelect.change( (_)->{
				curBackground.pos = ldtk.Json.BgImagePos.createByName( jSelect.val() );
				onBackgroundChange();
			});
		}

		// Bg pivot
		var jPivot = jForm.find(".pos>.pivot");
		jPivot.empty();
		if( curBackground.hasImage() ) {
			var imgInf = curBackground.getImageInfo(1, 1);
			if( imgInf!=null ) {
				jPivot.append( JsTools.createPivotEditor(
					curBackground.pivotX, curBackground.pivotY,
					true,
					Std.int( imgInf.tw ),
					Std.int( imgInf.th ),
					(x,y)->{
						curBackground.pivotX = x;
						curBackground.pivotY = y;
						onBackgroundChange();
					}
				));
			}
		}
	}

	function onCreateBackground(anchor:js.jquery.JQuery) {

		var bg = new Background(project, project.generateUniqueId_int());
		backgroundDefs.push(bg);

		editor.ge.emit( BackgroundDefAdded(bg) );
		onAnyChange();
		selectBackground(bg);
		jForm.find("input:not([readonly]):first").focus().select();
	}

	function onBackgroundChange() {
		editor.ge.emit( BackgroundDefChanged(curBackground) );
		updateList();
		updateForm();
		onAnyChange();
	}
}