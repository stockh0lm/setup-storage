function moveup() {
	var enabled_classes=document.getElementById("enabled_classes");
	previous_element=enabled_classes.selectedIndex - 1;
	current_element=enabled_classes.options[enabled_classes.selectedIndex ];
	

	var new_element = document.createElement('option');

	new_element.value=current_element.value;
	new_element.text=current_element.text;
	enabled_classes.add( new_element , enabled_classes.options[previous_element]);
	RmEnable();
}
function movedown() {
        var enabled_classes=document.getElementById("enabled_classes");
        previous_element=enabled_classes.selectedIndex +2;
        current_element=enabled_classes.options[enabled_classes.selectedIndex ];


        var new_element = document.createElement('option');

        new_element.value=current_element.value;
        new_element.text=current_element.text;
	if (previous_element>=enabled_classes.options.length) {
		enabled_classes.add( new_element , null );
		RmEnable();
		return true;
	}

        enabled_classes.add( new_element , enabled_classes.options[previous_element]);
        RmEnable();
	return true;
}



function AddEnable() {
	var enabled_classes=document.getElementById("enabled_classes");
	var availible_classes=document.getElementById("availible_classes");

	var new_element=document.createElement('option');
	new_element.value=availible_classes.value;
	new_element.text=availible_classes.value;
	if (CheckEnabled(new_element)==false) {
		enabled_classes.add(new_element,null);
	}

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
