function unpimp() {

	for (i=0; i<document.styleSheets.length;i++)
		document.styleSheets[i].disabled=true;
	
	return 0;

}	
