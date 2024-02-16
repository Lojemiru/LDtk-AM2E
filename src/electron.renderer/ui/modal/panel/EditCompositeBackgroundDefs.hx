package ui.modal.panel;

class EditCompositeBackgroundDefs extends ui.modal.Panel {
	var jList : js.jquery.JQuery;
	var jForm : js.jquery.JQuery;
	public var curTd : Null<data.def.CompositeBackgroundDef>;
	public var backgroundsForm : BackgroundDefsForm;
	var search : QuickSearch;

	public function new(?selectedDef:data.def.CompositeBackgroundDef) {
		super();

		//loadTemplate( "editTilesetDefs", "defEditor editTilesetDefs" );
		loadTemplate( "editCompositeBackgroundDefs", "defEditor editCompositeBackgroundDefs" );
		jList = jModalAndMask.find(".mainList ul");
		jForm = jModalAndMask.find("dl.form");
		linkToButton("button.editCompositeBackgrounds");


		// Create composite background
		jModalAndMask.find(".mainList button.create").click( function(ev) {
			var td = project.defs.createCompositeBackgroundDef();
			selectCompositeBackground(td);
			editor.ge.emit( CompositeBackgroundDefAdded(td) );
			jForm.find("input").first().focus().select();
		});

		// Create backgrounds editor
		backgroundsForm = new ui.BackgroundDefsForm( BP_Background(null) );
		jContent.find("#backgrounds").replaceWith( backgroundsForm.jWrapper );

		// Create quick search
		search = new ui.QuickSearch( jList );
		search.jWrapper.appendTo( jContent.find(".search") );

		selectCompositeBackground(selectedDef!=null ? selectedDef : project.defs.compositeBackgrounds[0]);
	}

	override function onGlobalEvent(e:GlobalEvent) {
		super.onGlobalEvent(e);
		switch e {
			case ProjectSettingsChanged, ProjectSelected, LevelSettingsChanged(_), LevelSelected(_):
				close();

			case CompositeBackgroundDefChanged(td):
				updateList();
				updateForm();
				updateBackgroundsForm();

			case _:
		}
	}

	function deleteCompositeBackgroundDef(td:data.def.CompositeBackgroundDef) {
		new LastChance(L.t._("Composite Background ::name:: deleted", { name:td.identifier }), project);
		var old = td;
		project.defs.removeCompositeBackgroundDef(td);
		selectCompositeBackground(project.defs.compositeBackgrounds[0]);
		editor.ge.emit( CompositeBackgroundDefRemoved(old) );
	}

	function selectCompositeBackground(td:data.def.CompositeBackgroundDef) {
		curTd = td;
		updateList();
		updateForm();
		updateBackgroundsForm();
	}

	function updateForm() {
		jForm.find("*").off(); // cleanup event listeners

		if( curTd==null ) {
			jForm.hide();
			jContent.find(".none").show();
			return;
		}

		jForm.show();
		jContent.find(".none").hide();

		// Fields
		var i = Input.linkToHtmlInput(curTd.identifier, jForm.find("input[name='name']") );
		i.fixValue = (v)->project.fixUniqueIdStr(v, (id)->project.defs.isCompositeBackgroundIdentifierUnique(id,curTd));
		i.onChange = editor.ge.emit.bind( CompositeBackgroundDefChanged(curTd) );

		// Tags
		var ted = new TagEditor(
			curTd.tags,
			()->editor.ge.emit(CompositeBackgroundDefChanged(curTd)),
			()->project.defs.getRecallTags(project.defs.compositeBackgrounds, td->td.tags),
			()->project.defs.compositeBackgrounds.map( td->td.tags ),
			(oldT,newT)->{
				for(td in project.defs.compositeBackgrounds)
					td.tags.rename(oldT,newT);
				editor.ge.emit( CompositeBackgroundDefChanged(curTd) );
			},
			true
		);
		jForm.find("#tags").empty().append(ted.jEditor);

		JsTools.parseComponents(jForm);
		checkBackup();
	}


	function updateList() {
		jList.empty();

		// List context menu
		ContextMenu.attachTo(jList, false, [
			{
				label: L._Paste(),
				cb: ()->{
					var copy = project.defs.pasteCompositeBackgroundDef(App.ME.clipboard);
					editor.ge.emit( CompositeBackgroundDefAdded(copy) );
					selectCompositeBackground(copy);
				},
				enable: ()->App.ME.clipboard.is(CCompositeBackgroundDef),
			},
		]);

		var tagGroups = project.defs.groupUsingTags(project.defs.compositeBackgrounds, td->td.tags);
		for( group in tagGroups) {
			// Tag name
			if( tagGroups.length>1 ) {
				var jSep = new J('<li class="title collapser"/>');
				jSep.text( group.tag==null ? L._Untagged() : group.tag );
				jSep.attr("id", project.iid+"_tileset_tag_"+group.tag);
				jSep.attr("default", "open");
				jSep.appendTo(jList);
			}

			var jLi = new J('<li class="subList"/>');
			jLi.appendTo(jList);
			var jSubList = new J('<ul class="niceList compact"/>');
			jSubList.appendTo(jLi);

			for(td in group.all) {
				var jLi = new J('<li class="draggable"/>');
				jSubList.append(jLi);

				jLi.append('<span class="name">'+td.identifier+'</span>');
				jLi.data("uid",td.uid);
				if( curTd==td )
					jLi.addClass("active");

				jLi.click( function(_) selectCompositeBackground(td) );

				ContextMenu.attachTo_new(jLi, (ctx:ContextMenu)->{
					ctx.addElement( Ctx_CopyPaster({
						elementName: "composite background",
						clipType: CCompositeBackgroundDef,
						copy: ()->App.ME.clipboard.copyData(CCompositeBackgroundDef, td.toJson()),
						cut: ()->{
							App.ME.clipboard.copyData(CCompositeBackgroundDef, td.toJson());
							deleteCompositeBackgroundDef(td);
						},
						paste: ()->{
							var copy = project.defs.pasteCompositeBackgroundDef(App.ME.clipboard, td);
							editor.ge.emit( CompositeBackgroundDefAdded(copy) );
							selectCompositeBackground(copy);
						},
						duplicate: ()->{
							var copy = project.defs.duplicateCompositeBackgroundDef(td);
							editor.ge.emit( CompositeBackgroundDefAdded(copy) );
							selectCompositeBackground(copy);
						},
						delete: ()->deleteCompositeBackgroundDef(td),
					}) );
				});
			}

			// Make list sortable
			JsTools.makeSortable(jSubList, function(ev) {
				var jItem = new J(ev.item);
				var fromIdx = project.defs.getCompositeBackgroundIndex( jItem.data("uid") );
				var toIdx = ev.newIndex>ev.oldIndex
					? jItem.prev().length==0 ? 0 : project.defs.getCompositeBackgroundIndex( jItem.prev().data("uid") )
					: jItem.next().length==0 ? project.defs.compositeBackgrounds.length-1 : project.defs.getCompositeBackgroundIndex( jItem.next().data("uid") );

				var moved = project.defs.sortCompositeBackgroundDef(fromIdx, toIdx);
				selectCompositeBackground(moved);
				editor.ge.emit(CompositeBackgroundDefSorted);
			}, { onlyDraggables:true });
		}

		JsTools.parseComponents(jList);
		checkBackup();
		search.run();
	}

	function updateBackgroundsForm() {
		if( curTd!=null )
			backgroundsForm.useBackgrounds(BP_Background(curTd), curTd.backgrounds);
		else {
			backgroundsForm.useBackgrounds(BP_Background(null), []);
			backgroundsForm.hide();
		}
		checkBackup();
	}
}