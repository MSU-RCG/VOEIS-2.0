dojo.provide("voeis.ui.ProjectSitesGrid");
dojo.require("dojox.grid.DataGrid");
dojo.require("voeis.Server");

voeis.ui.ProjectSitesGrid = function(projectId, server) {
    var server = server || voeis.Server.DEFAULT;
    var project = server.projects().get(projectId);
    var sitesDataStore = server.projectSitesDataStore(projectId);
    var grid = new dojox.grid.DataGrid({
        store: sitesDataStore,
        closable: true,
        structure: [
          {field: 'name', name: "Site", width: "auto"},
          {field: 'state', name: "State", width: "auto"}
        ]
    });
    dojo.connect(grid, "onRowDblClick", this, function(evt) {
        var item = grid.getItem(evt.rowIndex);
        if(item && item.id) {
            dojo.publish("voeis/project/site/selected", [projectId, item.id]);
        }
    });
    dojo.when(project, function(project) {
        grid.set("title", project.name);
    });
    return grid;
};

