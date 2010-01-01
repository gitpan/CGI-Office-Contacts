var record_report_cb =
{
	success: function(o)
	{
		var e = document.getElementById("report_result");

		if (o.responseText !== undefined)
		{
			var column_defs =
			[
			 {key: "number", label: "#"},
			 {key: "name",   label: "Name"},
			 {key: "type",   label: "Type"},
			];
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "name"},
			{key: "number"},
			{key: "type"},
			]
			};
			var data_table = new YAHOO.widget.DataTable("report_result", column_defs, json_data);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("report_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function report_onsubmit()
{
	var report = document.report_form.report_id.value;
	var option = document.report_form.report_id.options[report].text;
	option     = option.replace(/\s/, "_"); // To make a nice path info.

	if (option == "Records")
	{
		cb = record_report_cb;
	}
	else // Do nothing.
	{
		return true;
	}

	var p = YAHOO.util.Connect.setForm("report_form");
	var r = YAHOO.util.Connect.asyncRequest("POST", "<tmpl_var name=form_action>/report/display/" + option, cb);

	return false;
}
