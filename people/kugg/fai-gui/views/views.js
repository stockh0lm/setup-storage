function AddEnable() {
	var enabled_classes=document.getElementById("enabled_classes");
	var availible_classes=document.getElementById("availible_classes");

	var new_option=document.createElement('option');
	new_option.text=availible_classes.options[availible_classes.selectedIndex].value;
	if (CheckEnabled(new_option)==false) {
		enabled_classes.add(new_option,null);
	}

	/*docuement.list_selection.enabled_classes.add("karate");*/
}

function RmEnable() {
	var enabled_classes=document.getElementById("enabled_classes");
	enabled_classes.remove(enabled_classes.selectedIndex);
}

function CheckEnabled(new_option) {

        var enabled_classes=document.getElementById("enabled_classes");
	for(i=0;i<enabled_classes.options.length;i++) {
		if(enabled_classes.options[i].value==new_option.value) {
			alert(new_option.value + " is already enabled." );
			return true;
			/*It is enabled already*/
		}
		
	}
	return false;
}
